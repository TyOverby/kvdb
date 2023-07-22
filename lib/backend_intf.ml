open! Core

module type S = sig
  type t

  val create : path:string -> t Or_error.t

  val put
    :  t
    -> key:(read_write, _) Iobuf.t
    -> data:(read_write, _) Iobuf.t
    -> unit Or_error.t

  val get : t -> (read_write, _) Iobuf.t -> (read_write, _) Iobuf.t option Or_error.t
  val delete : t -> (read_write, _) Iobuf.t -> unit Or_error.t

  (* *)
  val flush : t -> unit Or_error.t
  val close : t -> unit Or_error.t

  module Iter : sig
    type t

    val get : t -> ((read_write, _) Iobuf.t * (read_write, _) Iobuf.t) option
    val next : t -> unit
    val is_valid : t -> bool
  end

  val iterate : ?seek_to:(read_write, _) Iobuf.t -> t -> Iter.t Or_error.t
end

module Backend = struct
  module type S = S

  module type M = sig
    module type S = S

    module Map_backend : S
    module Rocksdb_backend : S
  end
end
