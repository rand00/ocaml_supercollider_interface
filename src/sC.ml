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

open Lwt
module Osc_tmp = struct include Osc_lwt.Udp end
module Osc_server = Osc_tmp.Server
module Osc_client = Osc_tmp.Client

module Server = struct 

  let run_script () =
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


type nodeID = int32
type nodeID_seed = int32 ref

type client = Osc_client.t * Lwt_unix.sockaddr * nodeID_seed
type synth_node = {
  client : client;
  nodeID : nodeID;
  synth : string;
}

let create_nodeID_seed () = ref 1000l

let next_nodeID seed =
  let open Int32 in
  let i = !seed in 
  seed := succ i; i


module Client = struct

  let make ?(addr="127.0.0.1") ?(port=57110) () =
    let addr_unix = Unix.inet_addr_of_string addr in
    let addr_lwt = Lwt_unix.ADDR_INET (addr_unix, port) in
    let osc_client = (Lwt_main.run (Osc_client.create()))
    in osc_client, addr_lwt, create_nodeID_seed ()

  let quit_all (osc_client, addr, _) = 
    Lwt_main.run (
      Osc_client.send osc_client addr Osc.(Message {
          address = "/quit"; arguments = [] })
      >> Osc_client.destroy osc_client 
    )

end

module Synth = struct

  open Osc

  type arg_rhs = [
    | `F of float
    | `I of int
  ]

  type arg = string * arg_rhs

  let map_arg (var, value) = 
    match value with
    | `F f -> [ String var; Float32 f ]
    | `I i -> [ String var; Int32 (Int32.of_int i) ]

  let concat_map f l = 
    List.fold_right (fun e acc -> (f e) @ acc) l [] 

  let map_args args = concat_map map_arg args

  let send client message = 
    let (osc_client, addr, _) = client in
    Lwt.async (fun () -> Osc_client.send osc_client addr message)

  let start client synth args = 
    let (_, _, seed) = client in
    let nodeID = next_nodeID seed in
    let _ = send client (Message {
        address = "/s_new"; 
        arguments = [
          String synth; 
          Int32 nodeID; 
          Int32 0l; 
          Int32 0l; 
        ] @ (map_args args);
      }) 
    in { client; nodeID; synth }

  let modify node args = 
    send node.client (Message {
        address = "/n_set";
        arguments = [
          Int32 node.nodeID;
        ] @ (map_args args)
      })

  let stop node =
    send node.client (Message {
        address = "/n_free";
        arguments = [ Int32 node.nodeID ]
      })

end



