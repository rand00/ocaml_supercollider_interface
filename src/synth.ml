(*
  LambdaTactician - a cmd-line tactical lambda game.
  Copyright (C) 2014 Claes Worm 

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
*)

open Batteries 
open Core_rand00
open Lwt
open Osc_lwt.Udp 

module SynthServer = struct 

  let run () =
    Lwt_main.run
      (Lwt.async (fun () ->
           (if not (Sys.file_exists "log") then
              Lwt_unix.mkdir "log" 0o755
            else if not (Sys.is_directory "log") then
              failwith ("SynthServer: `log' is not a directory. ")
            else return ())
           >> Lwt_unix.system "./run_scsynth.sh 2>&1 > ./log/scsynth.log");
       return ())
end

module OSCClient = struct

  let init ?(addr="127.0.0.1") ?(port=57110) () =
    let addr_unix = Unix.inet_addr_of_string addr in
    let addr_lwt = Lwt_unix.ADDR_INET (addr_unix, port)
    in (Lwt_main.run (Client.create())), addr_lwt

  let quit_all (client, addr) =
    Lwt_main.run (
      Client.send client addr Osc.(Message {
          address = "/quit"; arguments = [] })
      >> Client.destroy client )

end

(** Internal functions - hide by mli*)

let curr_node_id = ref 1000l
let next_node_id () =
  let open Int32 in
  let i = !curr_node_id in
  let _ = curr_node_id := succ i
  in i


module type OSCClientWrapSig = sig
  val c : Osc_lwt.Udp.Client.t * Lwt_unix.sockaddr
end

module type S = sig

  type synth_args = [
    | `Dur of float
    | `Freq of float
    | `Mul of float
    | `PanR 
    | `PanL
  ]

  val make_synth : ?autofree:bool -> string -> synth_args list -> unit

  val sinew0 : synth_args list -> unit

  val ghostwind : synth_args list -> unit

  val ratata : synth_args list -> unit

  val synth_ghost2 : synth_args list -> unit

end

(** Make functor for convenience*)
module MakeSynth (OSCClientWrap : OSCClientWrapSig) = struct

  open Osc
  
  let client, addr = OSCClientWrap.c
  
  (** Types of synths args*)

  type synth_args = [
      `Dur of float
    | `Freq of float
    | `Mul of float
    | `PanR | `PanL
  ]

  (*make extendable pr. func. - or make a gadt?*)
  let map_arg = function
    | `Dur f  -> [ String "dur"; Float32 f ]
    | `Freq f -> [ String "freq"; Int32 (Int32.of_float f) ]
    | `Mul f -> [ String "mul"; Float32 f ]
    | `PanR -> [ String "panfrom"; Int32 (-1l) ]
    | `PanL -> [ String "panfrom"; Int32 1l ]

  let map_args args =
    List.concat (List.map map_arg args)

  let get_dur = function
    | `Dur f -> f | _ -> assert false

  let wait_duration ?(dur = 0.5) args =
    Lwt_unix.sleep
      (try
         (List.find (function | `Dur _ -> true | _ -> false) args)
         |> get_dur
       with Not_found -> dur)

  (*goto : rename this and pass synth_node_id separately 
    so other osc_msg_handlers can be used with this *)
  let make_osc_msgs synth args =
    let node_id = next_node_id () in
    let start = Osc.(Message {
        address = "/s_new"; 
        arguments = [
          String synth; 
          Int32 node_id; 
          Int32 0l; 
          Int32 0l; 
        ] @ (map_args args);
      }) in
    let stop = Osc.(Message {
        address = "/n_free";
        arguments = [ Int32 node_id ]
      })
    in start, stop

  (*goto: rename this to 'simple_synth'? or just make 'make_synth_handler' next *)
  let make_synth ?(autofree=false) synth args =
    Lwt_main.run
      (Lwt.async 
         (fun () ->
            let start, stop = make_osc_msgs synth args
            in Client.send client addr start
            (*goto: shouldn't it be possible to set duration even if no autofree?*)
            >> (if autofree then 
                  wait_duration args >> Client.send client addr stop
                else return ()));
       return ())


  (** Simple synth functions - for fx action/conseq sounds*)

  let sinew0 args = make_synth ~autofree:true "sinew" args
  let ghostwind args = make_synth "atmos_ghostwind" args
  let synth_ghost2 args = make_synth "synth_ghost2" args
  let ratata args = make_synth "ratata" args

  
end


let make () = 
  
  let _ = SynthServer.run () in (*goto : grep for 'server ready' in output of scsynth and get return-msg from thread*)
  let _ = Unix.sleep 4 in 
  let module C : OSCClientWrapSig = struct 
    let c = OSCClient.init () end in
  let _ = at_exit (fun () -> OSCClient.quit_all C.c) 
  in 
  (module MakeSynth (C) : S)





