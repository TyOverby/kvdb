open! Core
module String = Kvdb.Serializable.String
module Int = Kvdb.Serializable.Int64
module Int_to_string = Kvdb.Db.Make (Kvdb.Backend.Map_backend) (Int) (String)

module Int_to_string_star_string =
  Kvdb.Db.Make (Kvdb.Backend.Map_backend) (Int)
    (Kvdb.Serializable.Tuple2 (String) (String))

module Int_star_int_to_string =
  Kvdb.Db.Make (Kvdb.Backend.Map_backend) (Kvdb.Serializable.Tuple2 (Int) (Int)) (String)
