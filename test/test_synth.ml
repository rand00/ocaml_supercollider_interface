
(*
    | `Dur f  -> [ String "dur"; Float32 f ]
    | `Freq f -> [ String "freq"; Int32 (Int32.of_float f) ]
    | `Mul f -> [ String "mul"; Float32 f ]
    | `PanR -> [ String "panfrom"; Int32 (-1l) ]
    | `PanL -> [ String "panfrom"; Int32 1l ]
*)

module S = SC.Synth

let sleep t = Lwt_main.run (Lwt_unix.sleep t)

let test_01 c =
  let _ = S.synth c "ratata" [] in
  let _ = sleep 1.0 in
  let s' = S.synth c "sinew" [] in
  let _ = sleep 1.0 in
  let _ = S.synth c "ratata" [] in
  let _ = S.free s' in
  sleep 2.0

let s_ratata c = S.synth c "ratata" []
let s_sinew c = S.synth c "sinew" [] 

let rec switch c = function
  | 0 -> sleep 2.0
  | n -> 
    if n mod 2 = 0 then 
      let _ = (
        let _ = print_endline "even" in
        let _ = s_ratata c in
        sleep ((Random.float 1.0) +. 1.0); )
      in switch c (pred n)
    else 
      let _ = (
        let _ = print_endline "odd" in
        let s = s_sinew c in
        sleep ((Random.float 1.0) +. 1.0); 
        S.free s)
      in switch c (pred n)
      

let test_02 c = switch c 10

let freq_down s n = 
  for i = n downto 100 do 
    sleep 0.01; 
    S.set s [("freq", `I i)]
  done 

let test_03 c = 
  let s = s_sinew c in
  let _ = sleep 1.0 in
  freq_down s 1000

let _ = 
  
  let _ = SC.Server.run_script () in 
  let c = SC.Client.make () in
  let _ = test_03 c in
  SC.Client.quit_all c




