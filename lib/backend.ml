open! Core
include Backend_intf

module Map_backend = struct
  type t = string String.Map.t ref

  let create ~path:_ = Ok (ref String.Map.empty)

  let put t ~key ~data =
    let key = Iobuf.to_string key in
    let data = Iobuf.to_string data in
    Ok (Ref.replace t (fun t -> Map.set t ~key ~data))
  ;;

  let get t key =
    let key = Iobuf.to_string key in
    Ok (Map.find !t key |> Option.map ~f:Iobuf.of_string)
  ;;

  let delete t key =
    let key = Iobuf.to_string key in
    Ok (Ref.replace t (fun t -> Map.remove t key))
  ;;

  let flush _ = Ok ()
  let close _ = Ok ()

  module Iter = struct
    type t = (string * string) Sequence.t ref

    let get t =
      match Sequence.hd !t with
      | Some (k, v) -> Some (Iobuf.of_string k, Iobuf.of_string v)
      | None -> None
    ;;

    let next t =
      match Sequence.tl !t with
      | None -> t := Sequence.empty
      | Some x -> t := x
    ;;

    let is_valid t = not (Sequence.is_empty !t)
  end

  let iterate ?seek_to t =
    match seek_to with
    | None -> Ok (ref (Map.to_sequence !t))
    | Some seek_to ->
      let seek_to = Iobuf.to_string seek_to in
      Ok (ref (Map.to_sequence ~keys_greater_or_equal_to:seek_to !t))
  ;;
end

module Rocksdb_backend = struct
  type t =
    { db : Rocksdb.t
    ; write_options : Rocksdb.Options.Write_options.t
    ; read_options : Rocksdb.Options.Read_options.t
    ; flush_options : Rocksdb.Options.Flush_options.t
    }

  let convert_error = function
    | Ok t -> Ok t
    | Error (`Msg s) -> Error (Error.of_string s)
  ;;

  let create ~path =
    let db = Rocksdb.open_db ~config:Rocksdb.Options.default ~name:path in
    Or_error.map (convert_error db) ~f:(fun db ->
      let write_options = Rocksdb.Options.Write_options.create () in
      let read_options = Rocksdb.Options.Read_options.create () in
      let flush_options = Rocksdb.Options.Flush_options.create () in
      { db; write_options; read_options; flush_options })
  ;;

  let flush t = convert_error (Rocksdb.flush t.db t.flush_options)
  let close t = convert_error (Rocksdb.close_db t.db)

  let put t ~key ~data =
    let key = Iobuf.to_string key in
    let data = Iobuf.to_string data in
    convert_error (Rocksdb.put t.db t.write_options ~key ~value:data)
  ;;

  let get t key =
    let key = Iobuf.to_string key in
    Or_error.map
      (convert_error (Rocksdb.get t.db t.read_options key))
      ~f:(function
        | `Not_found -> None
        | `Found s -> Some (Iobuf.of_string s))
  ;;

  let delete t key =
    let key = Iobuf.to_string key in
    convert_error (Rocksdb.delete t.db t.write_options key)
  ;;

  module Iter = struct
    type t = Rocksdb.Iterator.iterator

    let get t =
      match Rocksdb.Iterator.get t with
      | Some (k, v) -> Some (Iobuf.of_string k, Iobuf.of_string v)
      | None -> None
    ;;

    let next = Rocksdb.Iterator.next
    let is_valid t = Rocksdb.Iterator.is_valid t
  end

  let iterate ?seek_to t =
    match convert_error (Rocksdb.Iterator.create t.db t.read_options), seek_to with
    | Error e, _ -> Error e
    | Ok iterator, None -> Ok iterator
    | Ok iterator, Some seek_to ->
      let seek_to = Iobuf.to_string seek_to in
      Rocksdb.Iterator.seek iterator seek_to;
      Ok iterator
  ;;
end
