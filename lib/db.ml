open! Core
include Db_intf

module Serializable = struct
  module type S = Serializable

  module Pair (A : S) (B : S) = struct
    type t = A.t * B.t

    let size (a, b) = A.size a + B.size b + 1

    let to_bytes (a, b) iobuf =
      A.to_bytes a iobuf;
      Iobuf.Fill.uint8_trunc iobuf 0;
      B.to_bytes b iobuf
    ;;

    let of_bytes iobuf =
      let a = A.of_bytes iobuf in
      let (_ : int) = Iobuf.Consume.int8 iobuf in
      let b = B.of_bytes iobuf in
      a, b
    ;;

    let to_string_for_testing (a, b) =
      sprintf "(%s, %s)" (A.to_string_for_testing a) (B.to_string_for_testing b)
    ;;
  end
end

module Make (Backend : Backend_intf.S) (Key : Serializable.S) (Data : Serializable.S) =
struct
  type t = Backend.t

  let create ~path = Backend.create ~path

  let put t ~key ~data =
    let key_buf = Iobuf.create ~len:(Key.size key) in
    Key.to_bytes key key_buf;
    Iobuf.reset key_buf;
    let data_buf = Iobuf.create ~len:(Data.size data) in
    Data.to_bytes data data_buf;
    Iobuf.reset data_buf;
    Backend.put t ~key:key_buf ~data:data_buf
  ;;

  let get t key =
    let key_buf = Iobuf.create ~len:(Key.size key) in
    Key.to_bytes key key_buf;
    Iobuf.reset key_buf;
    Backend.get t key_buf |> Option.map ~f:Data.of_bytes
  ;;

  let delete t key =
    let key_buf = Iobuf.create ~len:(Key.size key) in
    Key.to_bytes key key_buf;
    Iobuf.reset key_buf;
    Backend.delete t key_buf
  ;;

  module Iter = struct
    type t = Backend.Iter.t

    let get t =
      Option.map (Backend.Iter.get t) ~f:(fun (k, v) -> Key.of_bytes k, Data.of_bytes v)
    ;;

    let next = Backend.Iter.next
    let is_valid = Backend.Iter.is_valid
  end

  let iterate ?seek_to t =
    let seek_to =
      match seek_to with
      | Some key ->
        let key_buf = Iobuf.create ~len:(Key.size key) in
        Key.to_bytes key key_buf;
        Iobuf.reset key_buf;
        Some key_buf
      | None -> None
    in
    Backend.iterate ?seek_to t
  ;;

  let to_string_for_testing =
    let module Table = Ascii_table_kernel in
    let columns =
      [ Table.Column.create "key" (fun (key, _) -> Key.to_string_for_testing key)
      ; Table.Column.create "data" (fun (_, data) -> Data.to_string_for_testing data)
      ; Table.Column.create "key (bytes)" (fun (key, _) ->
          let key_buf = Iobuf.create ~len:(Key.size key) in
          Key.to_bytes key key_buf;
          Iobuf.reset key_buf;
          Iobuf.Limits.Hexdump.to_string_hum key_buf)
      ; Table.Column.create "data (bytes)" (fun (_, data) ->
          let data_buf = Iobuf.create ~len:(Data.size data) in
          Data.to_bytes data data_buf;
          Iobuf.reset data_buf;
          Iobuf.Limits.Hexdump.to_string_hum data_buf)
      ]
    in
    fun t ->
      let iter = iterate t in
      let rows = ref [] in
      while Iter.is_valid iter do
        let row = Iter.get iter |> Option.value_exn in
        rows := row :: !rows;
        Iter.next iter
      done;
      !rows
      |> List.rev
      |> Table.draw ~limit_width_to:300 ~prefer_split_on_spaces:false columns
      |> Option.value_exn
      |> Table.Screen.to_string ~bars:`Unicode ~string_with_attr:(fun _ s -> s)
  ;;
end
