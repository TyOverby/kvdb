open! Core

module Table =
  Kvdb.Db.Make (Kvdb.Backend.Rocksdb_backend) (Kvdb.Serializable.Int64)
    (Kvdb.Serializable.String)

let _main () =
  let open Or_error.Let_syntax in
  let%bind db = Table.create ~path:"/tmp/foo" in
  let%bind () = Table.put db ~key:5 ~data:"hello" in
  Ok ()
;;

let main2 () =
  let open Or_error.Let_syntax in
  let%bind db = Table.create ~path:"/tmp/foo" in
  let%bind result = Table.get db 5 in
  print_s [%message (result : string option)];
  Ok ()
;;

let () =
  match main2 () with
  | Ok () -> ()
  | Error e -> Error.raise e
;;
