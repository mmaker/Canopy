open Mirage

let disk = crunch "./disk"

let index_k =
  let doc = Key.Arg.info ~doc:"Index file name in remote." ["i"; "index"] in
  Key.(create "index" Arg.(opt string "Index" doc))

let name_k =
  let doc = Key.Arg.info ~doc:"Blog name." ["n"; "name"] in
  Key.(create "name" Arg.(opt string "Canopy" doc))

let port_k =
  let doc = Key.Arg.info ~doc:"Socket port." ["p"; "port"] in
  Key.(create "port" Arg.(opt int 8080 doc))

let push_hook_k =
  let doc = Key.Arg.info ~doc:"GitHub push hook." ["hook"] in
  Key.(create "push_hook" Arg.(opt string "push" doc))

let remote_k =
  let doc = Key.Arg.info ~doc:"Remote repository to fetch content." ["r"; "remote"] in
  Key.(create "remote" Arg.(opt string "https://github.com/Engil/__blog.git" doc))

let main =
  let libraries = [
      "cow";
      "decompress";
      "irmin.mirage";
      "irmin.git";
      "mirage-http";
      "tls.mirage";
    ] in
  let libraries = if get_mode () = `Xen then libraries else "irmin.unix" :: libraries in

  let packages = [
      "cow";
      "decompress";
      "irmin";
      "mirage-http";
      "mirage-flow";
      "tls";
      "mirage-types-lwt";
      "channel";
      "mirage-git";
      "re";
      "cohttp"
    ] in
  let packages = if get_mode () = `Xen then "mirage-xen" :: packages else "git-unix" :: packages in

  let keys = Key.([
                     abstract index_k;
                     abstract name_k;
                     abstract port_k;
                     abstract push_hook_k;
                     abstract remote_k
                   ]) in
  foreign
    ~libraries
    ~deps:[abstract nocrypto]
    ~keys
    ~packages
    "Canopy_main.Main" (console @-> resolver @-> conduit @-> http @-> kv_ro @-> job)

let stack =
  match get_mode () with
  | `Xen -> generic_stackv4 default_console tap0
  | `Unix -> socket_stackv4 default_console [Ipaddr.V4.any]

let conduit = conduit_direct ~tls:true stack
let http_srv = http_server conduit
let res_dns = resolver_dns stack

let () =
  register "canopy" [
    main $ default_console $ res_dns $ conduit $ http_srv $ disk
  ]
