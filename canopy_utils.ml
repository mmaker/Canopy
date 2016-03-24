let assoc_opt k l =
  match List.assoc k l with
  | v -> Some v
  | exception Not_found -> None

let map_opt fn default = function
  | None -> default
  | Some v -> fn v

let list_map_opt f =
  let rec aux acc = function
    | [] -> acc
    | (Some x)::xs -> aux ((f x)::acc) xs
    | None::xs -> aux acc xs
  in
  aux []

let default_opt default = function
  | None -> default
  | Some v -> v

let (++) = List.append

module KeyHashtbl = struct
    module KeyHash = struct
	type t = string list
	let equal = (=)
	let hash = Hashtbl.hash
      end

    module H = Hashtbl.Make(KeyHash)
    include H

    let find_opt t k =
      try Some (H.find t k) with
      | Not_found -> None
end
