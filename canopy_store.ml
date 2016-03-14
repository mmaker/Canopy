open Lwt.Infix
open V1_LWT
open Canopy_config

module Store (C: CONSOLE) (CTX: Irmin_mirage.CONTEXT) (INFL: Git.Inflate.S) = struct

  module Hash = Irmin.Hash.SHA1
  module Mirage_git_memory = Irmin_mirage.Irmin_git.Memory(CTX)(INFL)
  module Store = Mirage_git_memory(Irmin.Contents.String)(Irmin.Ref.String)(Hash)
  module Sync = Irmin.Sync(Store)
  module Topological = Graph.Topological.Make(Store.History)

  let store_config = Irmin_mem.config ()
  let task s = Irmin.Task.create ~date:0L ~owner:"Server" s
  let config = Canopy_config.config ()
  let repo _ = Store.Repo.create store_config
  let new_task _ = repo () >>= Store.master task
  let upstream = Irmin.remote_uri config.remote_uri

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

  let last_updated_commit_id commit key =
    repo () >>= fun repo ->
    new_task () >>= fun t  ->
    Store.read_exn (t "Reading file") key >>= fun current_file ->
    let aux commit_id acc =
      acc >>= fun (acc, matched) ->
      Store.of_commit_id (Irmin.Task.none) commit_id repo >>= fun store ->
      Store.read (store ()) key >>= fun readed_file ->
      match readed_file with
      | Some readed_file ->
        let matching = current_file = readed_file in
        let res =
          if current_file = readed_file
          then if matched then acc else commit_id
          else commit_id in
        Lwt.return (res, matching)
      | None -> Lwt.return (commit_id, true) in
    Store.history (t "Reading history") >>= fun history ->
    Topological.fold aux history (Lwt.return (commit, false))
    >>= fun (c, _) -> Lwt.return c

  let date_updated_last key =
    new_task () >>= fun t  ->
    repo () >>= fun repo ->
    Store.head_exn (t "Finding head") >>= fun head ->
    last_updated_commit_id head key >>= fun commit_id ->
    Store.Repo.task_of_commit_id repo commit_id >>= fun task ->
    let date = Irmin.Task.date task |> Int64.to_float in
    let cal = CalendarLib.Calendar.from_unixfloat date in
    CalendarLib.Printer.Calendar.sprint "%d/%m/%Y" cal |> Lwt.return

  let update console article_hashtbl =
    let open Canopy_types in

    let iter_fn key value =
      value >>= fun value ->
      date_updated_last key >>= fun date ->
      let uri = List.fold_left (fun s a -> s ^ "/" ^ a) "" key in
      match article_of_string uri value date with
      | None -> Lwt.return_unit
      | Some article -> KeyHashtbl.replace article_hashtbl key article |> Lwt.return
    in
    pull console >>= fun () ->
    new_task () >>= fun t ->
    Store.iter (t "Iterating through values") iter_fn

end
