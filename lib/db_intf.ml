open! Core

module type Serializable = sig
  type t

  val size : t -> int
  val to_bytes : t -> (read_write, Iobuf.seek) Iobuf.t -> unit
  val of_bytes : (read_write, Iobuf.seek) Iobuf.t -> t
  val to_string_for_testing : t -> string
end

module type S = sig
  module Key : Serializable
  module Data : Serializable
  module Backend : Backend.S

  type t

  val create : path:string -> t Or_error.t
  val put : t -> key:Key.t -> data:Data.t -> unit Or_error.t
  val get : t -> Key.t -> Data.t option Or_error.t
  val delete : t -> Key.t -> unit Or_error.t
  val to_string_for_testing : t -> string

  module Iter : sig
    type t

    val get : t -> (Key.t * Data.t) option
    val next : t -> unit
    val is_valid : t -> bool
  end

  val iterate : ?seek_to:Key.t -> t -> Iter.t Or_error.t
end

module Db = struct
  module type S = S

  module type M = sig
    module type S = S

    module Serializable : sig
      module type S = Serializable

      module Pair (A : S) (B : S) : S with type t = A.t * B.t
      module String : S with type t = string
      module Int : S with type t = int
    end

    module Make (Backend : Backend_intf.S) (Key : Serializable.S) (Data : Serializable.S) :
      S with module Backend := Backend and module Key := Key and module Data := Data
  end
end
