open! Core

module type S = sig
  module Key : Serializable.S
  module Data : Serializable.S
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

    module Make (Backend : Backend_intf.S) (Key : Serializable.S) (Data : Serializable.S) :
      S with module Backend := Backend and module Key := Key and module Data := Data
  end
end
