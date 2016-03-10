open Canopy_types

let template_links keys =
  let paths = List.map (function
      | x::_ -> x
      | _ -> assert false
    ) keys |> List.sort_uniq (Pervasives.compare) in
  let format_link link = Printf.sprintf
      "<li><a href='/%s'><span>%s</span></a></li>" link link in
  List.fold_left (fun str link -> str ^ (format_link link)) "" paths

let template_main ~content ~title ~keys =
    let links = template_links keys in
    Printf.sprintf "
<html>
<head>
<title>%s</title>
<link rel='stylesheet' href='/static/bower/bootstrap/dist/css/bootstrap.min.css'>
<link rel='stylesheet' href='/static/css/style.css'>
<script src='/static/bower/jquery/dist/jquery.min.js'></script>
<script src='/static/bower/bootstrap/dist/js/bootstrap.min.js'></script>
</head>

<body>
  <nav class='navbar navbar-default navbar-fixed-top'>
    <div class='container'>
      <div class='navbar-header'>
      <button type='button' class='navbar-toggle collapsed' data-toggle='collapse' data-target='.navbar-collapse'>
        <span class='sr-only'>Toggle navigation</span>
        <span class='icon-bar'></span>
        <span class='icon-bar'></span>
        <span class='icon-bar'></span>
      </button>
        <a class='navbar-brand' href='#'>Canopy blog engine</a>
      </div>
      <div class='collapse navbar-collapse collapse'>
        <ul class='nav navbar-nav navbar-right'>
      %s
</ul>
      </div>
    </div>
  </nav>
  <main>
      %s
</main>
</body>
" title links content


let template_article article =
  Printf.sprintf "
  <div class='flex-container'>
    <div class='post'>
      <h2>
        %s
      </h2>
<span class='author'>Written by %s</span>
      <br />
      <article>
        %s
      </article>
    </div>
" article.title article.author article.content

let template_listing_entry article =
  let abstract = match article.abstract with
  | None -> ""
  | Some abstract -> Printf.sprintf
                       "<p class='list-group-item-text abstract'>%s</p>" abstract in
 Printf.sprintf
 "
<a href='%s' class='list-group-item'>
<h4 class='list-group-item-heading'>%s</h4>
<span class='author'>Written by %s</span>
<br />
%s
</a>
  " article.uri article.title article.author abstract

let template_listing articles =
  let entries = List.fold_left (fun s article ->
      s ^ (template_listing_entry article)) "" articles in
  Printf.sprintf
"
    <div class='flex-container'>
      <div class='list-group listing'>
%s
      </div>
    </div>
" entries
