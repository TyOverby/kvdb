open! Core

module type Stringable = sig
  type t

  val to_string : t -> string
  val of_string : string -> t
  val to_string_for_testing : t -> string
end

module type S = sig
  module Key : Stringable
  module Data : Stringable
  module Backend : Backend.S

  type t

  val create : path:string -> t
  val put : t -> key:Key.t -> data:Data.t -> unit
  val get : t -> Key.t -> Data.t option
  val delete : t -> Key.t -> unit
  val to_string_for_testing : t -> string

  module Iter : sig
    type t

    val get : t -> (Key.t * Data.t) option
    val next : t -> unit
    val is_valid : t -> bool
  end

  val iterate : ?seek_to:Key.t -> t -> Iter.t
end

module Db = struct
  module type S = S

  module type M = sig
    module type S = S

    module Make (Backend : Backend_intf.S) (Key : Stringable) (Data : Stringable) :
      S with module Backend := Backend and module Key := Key and module Data := Data
  end
end
