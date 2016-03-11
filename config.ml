open Mirage

let stack console = socket_stackv4 console [Ipaddr.V4.any]

let disk = crunch "./disk"

let remote_k =
  let doc = Key.Arg.info ~doc:"Remote repository to fetch content." ["r"; "remote"] in
  Key.(create "remote" Arg.(opt string "https://github.com/Engil/__blog.git" doc))

let main =
  let libraries = ["irmin.git"; "cow"; "mirage-http"; "irmin.mirage";"tls.mirage";] in
  let libraries = if get_mode () = `Xen then libraries else "irmin.unix" :: libraries in
  foreign
    ~libraries
    ~deps:[abstract nocrypto]
    ~packages:["irmin"; "mirage-http"; "mirage-flow";"tls";"cow";
               "mirage-types-lwt"; "channel"; "git"; "mirage-git"; "git-unix";"re";"cohttp"]
    "Canopy_main.Main" (console @-> resolver @-> conduit @-> http @-> kv_ro @-> job)

let () =
  let sv4 = stack default_console in
  let res_dns = resolver_dns sv4 in
  let conduit = conduit_direct sv4 ~tls:true in
  let http_srv = http_server conduit in
  register "canopy" [
    main $ default_console $ res_dns $ conduit $ http_srv $ disk
  ]
