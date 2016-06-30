type t = {
  remote_uri : string;
  blog_name : string;
  index_page : string;
  port : int;
  push_hook_path: string;
  tls_port : int option;
  uuid : string;
  root : string;
}

let config () = {
  remote_uri = Key_gen.remote ();
  index_page = Key_gen.index ();
  blog_name = Key_gen.name ();
  port = Key_gen.port ();
  push_hook_path = Key_gen.push_hook ();
  tls_port = Key_gen.tls_port ();
  uuid = Key_gen.uuid ();
  root = Key_gen.root ();
}
