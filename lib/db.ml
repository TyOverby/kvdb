open! Core
include Db_intf

module Make (Backend : Backend_intf.S) (Key : Stringable) (Data : Stringable) = struct
  type t = Backend.t

  let create ~path = Backend.create ~path

  let put t ~key ~data =
    Backend.put t ~key:(Key.to_string key) ~data:(Data.to_string data)
  ;;

  let get t key = Backend.get t (Key.to_string key) |> Option.map ~f:Data.of_string
  let delete t key = Backend.delete t (Key.to_string key)

  module Iter = struct
    type t = Backend.Iter.t

    let get t =
      Option.map (Backend.Iter.get t) ~f:(fun (k, v) -> Key.of_string k, Data.of_string v)
    ;;

    let next = Backend.Iter.next
    let is_valid = Backend.Iter.is_valid
  end

  let iterate ?seek_to t =
    let seek_to = Option.map seek_to ~f:Key.to_string in
    Backend.iterate ?seek_to t
  ;;

  let to_string_for_testing =
    let module Table = Ascii_table_kernel in
    let columns =
      [ Table.Column.create "key" (fun (key, _) -> Key.to_string_for_testing key)
      ; Table.Column.create "data" (fun (_, data) -> Data.to_string_for_testing data)
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
      |> Table.draw ~limit_width_to:90 ~prefer_split_on_spaces:false columns
      |> Option.value_exn
      |> Table.Screen.to_string ~bars:`Unicode ~string_with_attr:(fun _ s -> s)
  ;;
end
