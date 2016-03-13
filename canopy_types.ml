type article = {
  title : string;
  content : string;
  author : string;
  abstract : string option;
  uri : string;
}

type page = [`Article of article | `Binary of bytes]

let meta_assoc str =
  Re_str.split (Re_str.regexp "\n") str |>
  List.map (fun meta ->
      let reg = Re_str.regexp "\\(.*\\): \\(.*\\)" in
      let _ = Re_str.string_match reg meta 0 in
      let key = Re_str.matched_group 1 meta in
      let value = Re_str.matched_group 2 meta in
      key, value)

let endswith s t =
  let slen = Bytes.length s in
  let tlen = Bytes.length t in
  Bytes.sub s (slen - tlen) tlen = t

let article_of_string uri str =
  if endswith uri "jpg" then `Binary str
  else try
    let r_meta = Re_str.regexp "---" in
    let s_str = Re_str.bounded_split r_meta str 2 in
    match s_str with
    | [meta; content] ->
      let content =
        try
          Cow.Markdown.of_string content |> Cow.Html.to_string
      with
      | _ -> content
      in
      let assoc = meta_assoc meta in
      let author = List.assoc "author" assoc in
      let title = List.assoc "title" assoc in
      let abstract =
        try
          Some (List.assoc "abstract" assoc)
        with
        | Not_found -> None
      in
      `Article {title; content; author; uri; abstract}
    | _ -> failwith "Failure reading article."
  with
  | _ -> failwith "Failure reading article."
