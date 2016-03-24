open Canopy_config
open Canopy_utils
open Html5.M

module StringPrinter = struct
    type out = string
    type m = string

    let empty = ""
    let concat = (^)
    let put a = a
    let make a = a
end

module StringHtml = Html5.Make_printer(StringPrinter)

let taglist tags =
  let format_tag tag =
    let taglink = Printf.sprintf "/tags/%s" in
    a ~a:[taglink tag |> a_href; a_class ["tag"]] [pcdata tag] in
  List.map format_tag tags |> div ~a:[a_class ["tags"]]

let links keys =
  let paths = List.map (function
			 | x::_ -> x
			 | _ -> assert false
		       ) keys |> List.sort_uniq (Pervasives.compare) in
  let format_link link =
    li [ a ~a:[a_href ("/" ^ link)] [span [pcdata link]]] in
 List.map format_link paths

let script_mathjax =
  [script ~a:[a_src "https://travis-ci.org/Engil/Canopy"] (pcdata "")]

let main ~config ~content ~title ~keys =
  let links = links keys in
  let mathjax = if config.mathjax then script_mathjax else [] in
  let page =
    html
      (head
	 (Html5.M.title (pcdata title))
	 ([
	   meta ~a:[a_charset "UTF-8"] ();
	   link ~rel:[`Stylesheet] ~href:"/static/bower/bootstrap/dist/css/bootstrap.min.css" ();
	   link ~rel:[`Stylesheet] ~href:"/static/css/style.css" ();
	   script ~a:[a_src "/static/bower/jquery/dist/jquery.min.js"] (pcdata "");
	   script ~a:[a_src "/static/bower/bootstrap/dist/js/bootstrap.min.js"] (pcdata "")
	 ] ++ mathjax)
      )
      (body
	 [
	   nav ~a:[a_class ["navbar navbar-default navbar-fixed-top"]] [
		 div ~a:[a_class ["container"]] [
		       div ~a:[a_class ["navbar-header"]] [
			     button ~a:[a_class ["navbar-toggle collapsed"];
					a_user_data "toggle" "collapse";
					a_user_data "target" ".navbar-collapse"
				       ] [
				      span ~a:[a_class ["icon-bar"]][];
				      span ~a:[a_class ["icon-bar"]][];
				      span ~a:[a_class ["icon-bar"]][]
				    ];
			     a ~a:[a_class ["navbar-brand"]; a_href ("/" ^ config.index_page)][pcdata config.blog_name]
			   ];
		       div ~a:[a_class ["collapse navbar-collapse collapse"]] [
			     ul ~a:[a_class ["nav navbar-nav navbar-right"]] links
			   ]
		     ]
	       ];
	   main [
	       div ~a:[a_class ["flex-container"]] content
	     ]
	 ]
      )
  in
  StringHtml.print page

let listing entries =
  [div ~a:[a_class ["flex-container"]] [
	 div ~a:[a_class ["list-group listing"]] entries
       ]
  ]

let error msg =
  [div ~a:[a_class ["alert alert-danger"]] [pcdata msg]]

let empty =
  div []
