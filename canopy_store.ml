open Lwt.Infix
open V1_LWT
open Canopy_config

module Store (C: CONSOLE) (CTX: Irmin_mirage.CONTEXT) (INFL: Git.Inflate.S) = struct

  module Hash = Irmin.Hash.SHA1
  module Mirage_git_memory = Irmin_mirage.Irmin_git.Memory(CTX)(INFL)
  module Store = Mirage_git_memory(Irmin.Contents.String)(Irmin.Ref.String)(Hash)
  module Sync = Irmin.Sync(Store)

  let store_config = Irmin_mem.config ()
  let task s = Irmin.Task.create ~date:0L ~owner:"Server" s
  let config = Canopy_config.config ()
  let new_task _ = Store.Repo.create store_config >>= Store.master task
  let upstream = Irmin.remote_uri config.remote_uri

  let get_articles keys =
    new_task () >>= fun t ->
    Lwt_list.map_s (fun key ->
        Store.read (t "Reading single post") key >>= function
        | None -> Lwt.return_none
        | Some str ->
          let uri = List.fold_left (fun s a -> s ^ "/" ^ a) "" key in
          Canopy_types.article_of_string uri str |> Lwt.return)
      keys

  let get_subkeys key =
    new_task () >>= fun t ->
    Store.list (t "Reading posts") key

  let get_key key =
    new_task () >>= fun t ->
    Store.read (t "Read post") key

  let pull console =
    new_task () >>= fun t ->
    Lwt.return (C.log console "Pulling repository") >>= fun _ ->
    Lwt.catch
      (fun () ->
         Sync.pull_exn (t "Updating") upstream `Update >>= fun _ ->
         Lwt.return (C.log console "Repository pulled"))
      (fun e ->
         let msg = Printf.sprintf "Fail pull %s" (Printexc.to_string e) in
         Lwt.return (C.log console msg))

end
