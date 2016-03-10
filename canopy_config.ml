type t = {
  remote_uri : string;
  index_page : string;
  port : int;
  push_hook_path: string;
}

let config = {
  remote_uri = "https://github.com/Engil/__blog.git";
  index_page = "Index";
  port = 8080;
  push_hook_path = "push";
}
