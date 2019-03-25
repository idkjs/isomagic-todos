type value =
  [ `Null
  | `Bool of bool
  | `Float of float
  | `String of string
  | `A of value list
  | `O of (string * value) list ]

type t =
  [ `A of value list
  | `O of (string * value) list ]

let value: t -> value = fun t -> (t :> value)

exception Escape of ((int * int) * (int * int)) * Jsonm.error

let json_of_src src =
  let d = Jsonm.decoder src in
  let dec () = match Jsonm.decode d with
    | `Lexeme l -> l
    | `Error e  -> raise (Escape (Jsonm.decoded_range d, e))
    | `End
    | `Await    -> assert false
  in
  let rec value v k = match v with
    | `Os -> obj [] k
    | `As -> arr [] k
    | `Null
    | `Bool _
    | `String _
    | `Float _ as v -> k v
    | _ -> assert false
  and arr vs k = match dec () with
    | `Ae -> k (`A (List.rev vs))
    | v   -> value v (fun v -> arr (v :: vs) k)
  and obj ms k = match dec () with
    | `Oe     -> k (`O (List.rev ms))
    | `Name n -> value (dec ()) (fun v -> obj ((n, v) :: ms) k)
    | _       -> assert false
  in
  try `JSON (value (dec ()) (fun x -> x))
  with Escape (r, e) -> `Error (r, e)

let to_dst ?(minify=true) dst json =
  let enc e l = ignore (Jsonm.encode e (`Lexeme l)) in
  let rec t v k e = match v with
    | `A vs -> arr vs k e
    | `O ms -> obj ms k e
  and value v k e = match v with
    | `Null | `Bool _ | `Float _ | `String _ as v -> enc e v; k e
    | #t as x -> t (x :> t) k e
  and arr vs k e = enc e `As; arr_vs vs k e
  and arr_vs vs k e = match vs with
    | v :: vs' -> value v (arr_vs vs' k) e
    | [] -> enc e `Ae; k e
  and obj ms k e = enc e `Os; obj_ms ms k e
  and obj_ms ms k e = match ms with
    | (n, v) :: ms -> enc e (`Name n); value v (obj_ms ms k) e
    | [] -> enc e `Oe; k e
  in
  let e = Jsonm.encoder ~minify dst in
  let finish e = ignore (Jsonm.encode e `End) in
  value json finish e

let to_buffer ?minify buf json =
  to_dst ?minify (`Buffer buf) json

let to_string ?minify json =
  let buf = Buffer.create 1024 in
  to_buffer ?minify buf json;
  Buffer.contents buf

let to_channel ?minify oc json =
  to_dst ?minify (`Channel oc) json

exception Parse_error of value * string

let parse_error t fmt =
  Printf.kprintf (fun msg ->
      raise (Parse_error (t, msg))
    ) fmt

let wrap t = `A [t]

let unwrap = function
  | `A [t] -> t
  | v -> parse_error (v :> value) "Not unwrappable"

let string_of_error error =
  Jsonm.pp_error Format.str_formatter error;
  Format.flush_str_formatter ()

let from_src src =
  match json_of_src src with
  | `JSON t      -> t
  | `Error (_,e) -> parse_error `Null "JSON.of_buffer %s" (string_of_error e)

let from_string str = from_src (`String str)

let from_channel chan = from_src (`Channel chan)