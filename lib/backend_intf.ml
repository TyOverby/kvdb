open! Core

module type S = sig
  type t

  val create : path:string -> t
  val put : t -> key:(read_write, _) Iobuf.t -> data:(read_write, _) Iobuf.t -> unit
  val get : t -> (read_write, _) Iobuf.t -> (read_write, _) Iobuf.t option
  val delete : t -> (read_write, _) Iobuf.t -> unit

  module Iter : sig
    type t

    val get : t -> ((read_write, _) Iobuf.t * (read_write, _) Iobuf.t) option
    val next : t -> unit
    val is_valid : t -> bool
  end

  val iterate : ?seek_to:(read_write, _) Iobuf.t -> t -> Iter.t
end

module Backend = struct
  module type S = S

  module type M = sig
    module type S = S

    module Map_backend : S
  end
end
