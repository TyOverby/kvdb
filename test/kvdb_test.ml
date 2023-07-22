open! Core

module Int = struct
  include Int

  let to_string (i : int) : string =
    let buf = Iobuf.create ~len:8 in
    Iobuf.Poke.int64_be buf i ~pos:0;
    Iobuf.to_string buf
  ;;

  let of_string (s : string) : int =
    let buf = Iobuf.of_string s in
    Iobuf.Consume.int64_be_exn buf
  ;;

  let to_string_for_testing = Int.to_string
end

module String = struct
  include String

  let to_string_for_testing = Fn.id
end

module Int_to_string = Kvdb.Db.Make (Kvdb.Backend.Map_backend) (Int) (String)

let%expect_test "empty table" =
  let t = Int_to_string.create ~path:"foo" in
  print_endline (Int_to_string.to_string_for_testing t);
  [%expect
    {|
    ┌─────┬──────┐
    │ key │ data │
    ├┬┬┬┬┬┼┬┬┬┬┬┬┤
    └┴┴┴┴┴┴┴┴┴┴┴┴┘
    |}]
;;

let%expect_test "single put" =
  let t = Int_to_string.create ~path:"foo" in
  Int_to_string.put t ~key:0 ~data:"hi";
  print_endline (Int_to_string.to_string_for_testing t);
  [%expect
    {|
    ┌─────┬──────┐
    │ key │ data │
    ├─────┼──────┤
    │ 0   │ hi   │
    └─────┴──────┘ |}]
;;

let%expect_test "multi put" =
  let t = Int_to_string.create ~path:"foo" in
  Int_to_string.put t ~key:0 ~data:"hello";
  Int_to_string.put t ~key:1 ~data:"world";
  print_endline (Int_to_string.to_string_for_testing t);
  [%expect
    {|
    ┌─────┬───────┐
    │ key │ data  │
    ├─────┼───────┤
    │ 0   │ hello │
    │ 1   │ world │
    └─────┴───────┘ |}]
;;

let%expect_test "put and then delete" =
  let t = Int_to_string.create ~path:"foo" in
  Int_to_string.put t ~key:0 ~data:"hello";
  Int_to_string.put t ~key:1 ~data:"world";
  print_endline (Int_to_string.to_string_for_testing t);
  [%expect
    {|
    ┌─────┬───────┐
    │ key │ data  │
    ├─────┼───────┤
    │ 0   │ hello │
    │ 1   │ world │
    └─────┴───────┘ |}];
  Int_to_string.delete t 0;
  print_endline (Int_to_string.to_string_for_testing t);
  [%expect
    {|
    ┌─────┬───────┐
    │ key │ data  │
    ├─────┼───────┤
    │ 1   │ world │
    └─────┴───────┘ |}]
;;
