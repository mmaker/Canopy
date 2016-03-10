type t = {
  remote_uri : string;
  index_page : string;
  port : int;
}

let config = {
  remote_uri = "https://github.com/Engil/__blog.git";
  index_page = "Index.md";
  port = 8080;
}
