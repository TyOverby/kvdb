open! Core
open Common
module Table = Int_star_int_to_string

let%expect_test "empty table" =
  let t = Table.create ~path:"foo" |> Or_error.ok_exn in
  print_endline (Table.to_string_for_testing t);
  [%expect
    {|
    ┌─────┬──────┬─────────────┬──────────────┐
    │ key │ data │ key (bytes) │ data (bytes) │
    ├┬┬┬┬┬┼┬┬┬┬┬┬┼┬┬┬┬┬┬┬┬┬┬┬┬┬┼┬┬┬┬┬┬┬┬┬┬┬┬┬┬┤
    └┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┘
    |}]
;;

let%expect_test "single put" =
  let t = Table.create ~path:"foo" |> Or_error.ok_exn in
  Table.put t ~key:(0, 0) ~data:"hi" |> Or_error.ok_exn;
  print_endline (Table.to_string_for_testing t);
  [%expect
    {|
    ┌────────┬──────┬────────────────────────────────────────────────────────────────────────────────┬──────────────────────────────────────────────────────────────────────────┐
    │ key    │ data │ key (bytes)                                                                    │ data (bytes)                                                             │
    ├────────┼──────┼────────────────────────────────────────────────────────────────────────────────┼──────────────────────────────────────────────────────────────────────────┤
    │ (0, 0) │ hi   │ 00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................| │ 00000000  00 00 00 00 00 00 00 02  68 69                    |........hi| │
    │        │      │ 00000010  00                                                |.|                │                                                                          │
    └────────┴──────┴────────────────────────────────────────────────────────────────────────────────┴──────────────────────────────────────────────────────────────────────────┘ |}]
;;

let%expect_test "multi put" =
  let t = Table.create ~path:"foo" |> Or_error.ok_exn in
  Table.put t ~key:(0, 0) ~data:"a" |> Or_error.ok_exn;
  Table.put t ~key:(0, 1) ~data:"b" |> Or_error.ok_exn;
  Table.put t ~key:(1, 0) ~data:"c" |> Or_error.ok_exn;
  Table.put t ~key:(1, 1) ~data:"d" |> Or_error.ok_exn;
  print_endline (Table.to_string_for_testing t);
  [%expect
    {|
    ┌────────┬──────┬────────────────────────────────────────────────────────────────────────────────┬─────────────────────────────────────────────────────────────────────────┐
    │ key    │ data │ key (bytes)                                                                    │ data (bytes)                                                            │
    ├────────┼──────┼────────────────────────────────────────────────────────────────────────────────┼─────────────────────────────────────────────────────────────────────────┤
    │ (0, 0) │ a    │ 00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................| │ 00000000  00 00 00 00 00 00 00 01  61                       |........a| │
    │        │      │ 00000010  00                                                |.|                │                                                                         │
    │ (0, 1) │ b    │ 00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................| │ 00000000  00 00 00 00 00 00 00 01  62                       |........b| │
    │        │      │ 00000010  01                                                |.|                │                                                                         │
    │ (1, 0) │ c    │ 00000000  00 00 00 00 00 00 00 01  00 00 00 00 00 00 00 00  |................| │ 00000000  00 00 00 00 00 00 00 01  63                       |........c| │
    │        │      │ 00000010  00                                                |.|                │                                                                         │
    │ (1, 1) │ d    │ 00000000  00 00 00 00 00 00 00 01  00 00 00 00 00 00 00 00  |................| │ 00000000  00 00 00 00 00 00 00 01  64                       |........d| │
    │        │      │ 00000010  01                                                |.|                │                                                                         │
    └────────┴──────┴────────────────────────────────────────────────────────────────────────────────┴─────────────────────────────────────────────────────────────────────────┘ |}]
;;
