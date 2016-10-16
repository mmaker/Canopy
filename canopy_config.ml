type t = {
  remote_uri : string;
  remote_branch : string option;
  blog_name : string;
  index_page : string;
  port : int;
  push_hook_path: string;
  tls_port : int option;
  uuid : string;
  root : string;
}

let decompose_git_url url =
    match String.rindex url '#' with
    | exception Not_found -> (url, None)
    | i ->
      let remote_url = String.sub url 0 i in
      let branch = String.sub url (i + 1) (String.length url - i - 1) in
      (remote_url, Some branch)

let remote_uri () = fst (decompose_git_url (Key_gen.remote ()))
let remote_branch () = snd (decompose_git_url (Key_gen.remote ()))

let config () = {
  remote_uri = remote_uri ();
  remote_branch = remote_branch ();
  index_page = Key_gen.index ();
  blog_name = Key_gen.name ();
  port = Key_gen.port ();
  push_hook_path = Key_gen.push_hook ();
  tls_port = Key_gen.tls_port ();
  uuid = Key_gen.uuid ();
  root = Key_gen.root ();
}
