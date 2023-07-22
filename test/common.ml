open! Core
module String = Kvdb.Db.Serializable.String
module Int = Kvdb.Db.Serializable.Int
module Int_to_string = Kvdb.Db.Make (Kvdb.Backend.Map_backend) (Int) (String)

module Int_to_string_star_string =
  Kvdb.Db.Make (Kvdb.Backend.Map_backend) (Int)
    (Kvdb.Db.Serializable.Pair (String) (String))

module Int_star_int_to_string =
  Kvdb.Db.Make (Kvdb.Backend.Map_backend) (Kvdb.Db.Serializable.Pair (Int) (Int)) (String)
