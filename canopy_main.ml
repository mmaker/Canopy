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
    let open Canopy_utils in
    let config = Canopy_config.config () in
    let module Context =
      ( struct
        let v _ = Lwt.return_some (res, ctx)
      end : Irmin_mirage.CONTEXT)
    in
    let module Store = Canopy_store.Store(C)(Context)(Inflator) in

    let content_hashtbl = KeyHashtbl.create 32 in

    let respond_html ~status ~content ~title =
      Store.get_subkeys [] >>= fun keys ->
      let body = Canopy_templates.main ~config ~content ~title ~keys in
      S.respond_string ~status ~body () in

    let respond_update = function
      | [] -> S.respond_string ~status:`OK ~body:"" ()
      | errors ->
	 let body = List.fold_left (fun a b -> a ^ "\n" ^ b) "" errors in
	 S.respond_string ~status:`Bad_request ~body () in

    Store.pull console >>= fun _ ->
    Store.fill_cache content_hashtbl >>=
    Lwt_list.iter_p (C.log_s console) >>= fun () ->

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
	 KeyHashtbl.clear content_hashtbl |> Lwt.return >>= fun _ ->
	 Store.fill_cache content_hashtbl >>=
	 respond_update

      | "tags"::tagname::_ ->
	 let aux _ v l =
	   if Canopy_content.find_tag tagname v then (v::l) else l in
      	 let content =
	   KeyHashtbl.fold aux content_hashtbl []
	   |> List.sort Canopy_content.compare
	   |> List.map Canopy_content.to_tyxml_listing_entry
	   |> Canopy_templates.listing in
	 respond_html ~status:`OK ~title:config.blog_name ~content

      | key ->
        begin
          match KeyHashtbl.find_opt content_hashtbl key with
            | None ->
              Store.get_subkeys key >>= fun keys ->
              if (List.length keys) = 0 then
                S.respond_string ~status:`Not_found ~body:"Not found" ()
              else
                let articles = List.map (KeyHashtbl.find_opt content_hashtbl) keys in
                let content =
		  list_reduce_opt articles
		  |> List.sort Canopy_content.compare
		  |> List.map Canopy_content.to_tyxml_listing_entry
		  |> Canopy_templates.listing in
                respond_html ~status:`OK ~title:"Listing" ~content
            | Some article ->
              let title, content = Canopy_content.to_tyxml article in
              respond_html ~status:`OK ~title ~content
        end

    in
    let callback _ request _ =
      let uri = Cohttp.Request.uri request in
      dispatcher (Uri.path uri)
    in
    let conn_closed (_,conn_id) =
      let cid = Cohttp.Connection.to_string conn_id in
      C.log console (Printf.sprintf "conn %s closed" cid)
    in
    http (`TCP config.port) (S.make ~conn_closed ~callback ())

end
