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

let net =
  match get_mode () with
  | `Xen -> `Direct
  | `Unix ->
     try match Sys.getenv "NET" with
         | "direct" -> `Direct
         | "socket" -> `Socket
         | _        -> `Direct
     with Not_found -> `Socket

let ipv4_conf =
  let i = Ipaddr.V4.of_string_exn in
  {
    address  = i "10.0.0.2";
    netmask  = i "255.255.255.0";
    gateways = [i "10.0.0.1"];
  }

let stack console =
  match net with
  | `Socket -> socket_stackv4 console [Ipaddr.V4.any]
  | `Direct ->
     try match Sys.getenv "DHCP" with
         | "no" -> direct_stackv4_with_static_ipv4 console tap0 ipv4_conf
         | "yes" -> direct_stackv4_with_dhcp console tap0
         | _ -> raise Not_found
     with Not_found -> failwith "Set DHCP to 'yes' or 'no'"


let () =
  let sv4 = stack default_console in
  let res_dns = resolver_dns sv4 in
  let conduit = conduit_direct sv4 ~tls:true in
  let http_srv = http_server conduit in

  register "canopy" [
    main $ default_console $ res_dns $ conduit $ http_srv $ disk
  ]
