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

  let start console res ctx http disk _ =

    let open Canopy_config in
    let open Canopy_types in
    let config = Canopy_config.config () in
    let module Context =
      ( struct
        let v _ = Lwt.return_some (res, ctx)
      end : Irmin_mirage.CONTEXT)
    in
    let module Store = Canopy_store.Store(C)(Context)(Inflator) in

    let flatten_option_list l =
      List.fold_left
        (fun xs x -> match x with
           | None -> xs
           | Some x -> x::xs) [] l in

    let respond_html ~status ~content ~title =
      Store.get_subkeys [] >>= fun keys ->
      let body = Canopy_templates.template_main ~config ~content ~title ~keys in
      S.respond_string ~status ~body () in

    Store.pull console >>= fun _ ->

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
        Store.pull console >>= fun _ ->
        S.respond_string ~status:`OK ~body:"" ()

      | key ->
        begin
          Store.get_key key >>= fun m_body ->
          match m_body with
            | None ->
              Store.get_subkeys key >>= fun keys ->
              if (List.length keys) = 0 then
                S.respond_string ~status:`Not_found ~body:"Not found" ()
              else
                Store.get_articles keys >>= fun articles ->
                let content = flatten_option_list articles |> Canopy_templates.template_listing in
                respond_html ~status:`OK ~title:"Listing" ~content
            | Some article ->
              Store.date_updated_last key >>= fun date ->
              match Canopy_types.article_of_string uri article date with
              | None ->
                S.respond_string ~status:`Not_found ~body:"Something really bad" ()
              | Some article ->
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
