open Lwt
open V1_LWT


module Main  (C: CONSOLE) (RES: Resolver_lwt.S) (CON: Conduit_mirage.S) (S:Cohttp_lwt.Server) (Disk: KV_RO)  = struct

  let read_fs fs path =
    Disk.size fs path
    >>= function
    | `Error (Disk.Unknown_key _) -> Lwt.return_none
    | `Ok size ->
      Disk.read fs path 0 (Int64.to_int size)
      >>= function
      | `Error (Disk.Unknown_key _) -> Lwt.return_none
      | `Ok bufs -> Lwt.return_some (Cstruct.copyv bufs)

  let task s = Irmin.Task.create ~date:0L ~owner:"Server"  s

  let start console res ctx http disk _ =

    let open Canopy_config in
    let open Canopy_types in

    let module Hash = Irmin.Hash.SHA1 in
    let module Context =
      ( struct
        let v _ = Lwt.return_some (res, ctx)
      end : Irmin_mirage.CONTEXT)
    in
    let module Mirage_git_memory = Irmin_mirage.Irmin_git.Memory(Context)(Git_unix.Zlib) in
    let module Store = Mirage_git_memory(Irmin.Contents.String)(Irmin.Ref.String)(Hash) in
    let module Sync = Irmin.Sync(Store) in
    let store_config = Irmin_mem.config () in
    let config = Canopy_config.config () in
    let new_task _ = Store.Repo.create store_config >>= Store.master task in

    let upstream = Irmin.remote_uri config.remote_uri in

    let flatten_option_list l =
      List.fold_left
        (fun xs x -> match x with
           | None -> xs
           | Some x -> x::xs) [] l in

    let get_articles keys =
      new_task () >>= fun t ->
      Lwt_list.map_s (fun key ->
          Store.read (t "Reading single post") key >>= function
          | None -> Lwt.return_none
          | Some str ->
            let uri = List.fold_left (fun s a -> s ^ "/" ^ a) "" key in
            Some (Canopy_types.article_of_string uri str) |> Lwt.return)
        keys in

    let respond_html ~status ~content ~title =
      new_task () >>= fun t ->
      Store.list (t "Reading posts") [] >>= fun keys ->
      let index = config.index_page in
      let name = config.blog_name in
      let body = Canopy_templates.template_main ~index ~content ~name ~title ~keys in
      S.respond_string ~status ~body () in

    new_task () >>= fun t ->
    let pull _ =
      Lwt.return (C.log console "Pulling repository") >>= fun _ ->
      Lwt.catch
        (fun () ->
         Sync.pull_exn (t "Updating") upstream `Update >>= fun _ ->
         Lwt.return (C.log console "Repository pulled"))
        (fun e ->
         let msg = Printf.sprintf "Fail pull %s" (Printexc.to_string e) in
         Lwt.return (C.log console msg))
    in
    pull () >>= fun _ ->
    let rec dispatcher uri =
      let s_uri = Re_str.split (Re_str.regexp "/") (Uri.pct_decode uri) in
      match s_uri with
      | "static"::_ ->
        begin
          read_fs disk uri >>= function
          | None ->
            S.respond_string ~status:`Not_found ~body:"Not found" ()
          | Some body ->
            S.respond_string ~status:`OK ~body ()
        end

      | [] ->
         dispatcher config.index_page
      | uri::[] when uri = config.push_hook_path ->
         pull () >>= fun _ ->
         S.respond_string ~status:`OK ~body:"" ()
      | key ->
        begin
          Store.read (t "Read post") key >>= fun m_body ->
          match m_body with
            | None ->
              Store.list (t "Read subfolders") key >>= fun keys ->
              get_articles keys >>= fun articles ->
              if (List.length articles = 0) then
                S.respond_string ~status:`Not_found ~body:"Not found" ()
              else
                 let content = flatten_option_list articles |>
                                 Canopy_templates.template_listing in
                 respond_html ~status:`OK ~title:"Listing" ~content
            | Some article ->
               match Canopy_types.article_of_string uri article with
               | `Binary blob ->
                  S.respond_string ~status:`OK ~body:blob ()
               | `Article article ->
                  let content = Canopy_templates.template_article article in
                  respond_html ~status:`OK ~title:article.title ~content
        end in

    let callback conn_id request body =
      let uri = Cohttp.Request.uri request in
      dispatcher (Uri.path uri)
    in
    let conn_closed (_,conn_id) =
      let cid = Cohttp.Connection.to_string conn_id in
      C.log console (Printf.sprintf "conn %s closed" cid)
    in
    http (`TCP config.port) (S.make ~conn_closed ~callback ())

end
