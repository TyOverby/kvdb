open! Core

module type S = sig
  type t

  val create : path:string -> t
  val put : t -> key:string -> data:string -> unit
  val get : t -> string -> string option
  val delete : t -> string -> unit

  module Iter : sig
    type t

    val get : t -> (string * string) option
    val next : t -> unit
    val is_valid : t -> bool
  end

  val iterate : ?seek_to:string -> t -> Iter.t
end

module Backend = struct
  module type S = S

  module type M = sig
    module type S = S

    module Map_backend : S
  end
end
