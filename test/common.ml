open! Core

module Int = struct
  type t = int

  let size _ = 8
  let to_bytes (i : int) buf = Iobuf.Fill.int64_be buf i
  let of_bytes buf = Iobuf.Consume.int64_be_exn buf
  let to_string_for_testing = Int.to_string
end

module String = struct
  type t = string

  let size s = String.length s + 8

  let to_bytes s buf =
    Iobuf.Fill.int64_be buf (String.length s);
    Iobuf.Fill.stringo buf s
  ;;

  let of_bytes buf =
    let len = Iobuf.Consume.int64_be_exn buf in
    Iobuf.Consume.stringo ~len buf
  ;;

  let to_string_for_testing = Fn.id
end

module Int_to_string = Kvdb.Db.Make (Kvdb.Backend.Map_backend) (Int) (String)

module Int_to_string_star_string =
  Kvdb.Db.Make (Kvdb.Backend.Map_backend) (Int)
    (Kvdb.Db.Serializable.Pair (String) (String))

module Int_star_int_to_string =
  Kvdb.Db.Make (Kvdb.Backend.Map_backend) (Kvdb.Db.Serializable.Pair (Int) (Int)) (String)
