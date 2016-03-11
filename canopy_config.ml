type t = {
  remote_uri : string;
  name : string;
  index_page : string;
  port : int;
  push_hook_path: string;
}

let config () = {
  remote_uri = Key_gen.remote ();
  index_page = "Index";
  name = "Canopy";
  port = 8080;
  push_hook_path = "push";
}
