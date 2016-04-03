open Canopy_utils
open Html5.M

type t = {
  title : string;
  content : string;
  author : string;
  abstract : string option;
  uri : string;
  date: CalendarLib.Calendar.t;
  tags: string list;
}

let of_string meta uri date content =
  try
    let split_tags = Re_str.split (Re_str.regexp ",") in
    let content = Cow.Markdown.of_string content |> Cow.Html.to_string in
    let author = List.assoc "author" meta in
    let title = List.assoc "title" meta in
    let tags = assoc_opt "tags" meta |> map_opt split_tags [] |> List.map String.trim in
    let abstract = assoc_opt "abstract" meta in
    Some {title; content; author; uri; abstract; date; tags}
  with
  | _ -> None

let to_tyxml article =
  let author = "Written by " ^ article.author in
  let date = calendar_to_pretty_date article.date in
  let updated = "Last updated: " ^ date in
  let tags = Canopy_templates.taglist article.tags in
  [div ~a:[a_class ["post"]] [
	 h2 [pcdata article.title];
	 span ~a:[a_class ["author"]] [pcdata author];
	 br ();
	 tags;
	 span ~a:[a_class ["date"]] [pcdata updated];
	 br ();
	 Html5.M.article [Unsafe.data article.content]
       ]]

let to_tyxml_listing_entry article =
  let author = "Written by " ^ article.author in
  let abstract = match article.abstract with
    | None -> []
    | Some abstract -> [p ~a:[a_class ["list-group-item-text abstract"]] [pcdata abstract]] in
  let content = [
      h4 ~a:[a_class ["list-group-item-heading"]] [pcdata article.title];
      span ~a:[a_class ["author"]] [pcdata author];
      br ();
    ] in
  a ~a:[a_href article.uri; a_class ["list-group-item"]] (content ++ abstract)
