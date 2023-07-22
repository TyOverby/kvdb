open! Core

module type S = sig
  type t

  val size : t -> int
  val to_bytes : t -> (read_write, Iobuf.seek) Iobuf.t -> unit
  val of_bytes : (read_write, Iobuf.seek) Iobuf.t -> t
  val to_string_for_testing : t -> string
end

module String : S with type t = string

(* signed int*)
module Int64 : S with type t = int
module Int63 : S with type t = Int63.t
module Int32 : S with type t = int
module Int16 : S with type t = int
module Int8 : S with type t = int

(* unsigned int *)
module Uint32 : S with type t = int
module Uint16 : S with type t = int
module Uint8 : S with type t = int

(* time *)
module Time_ns : S with type t = Core.Time_ns.t
module Time_ns_span : S with type t = Core.Time_ns.Span.t
module Time_sec : S with type t = Core.Time_ns.t
module Time_sec_span : S with type t = Core.Time_ns.Span.t

(* path *)
module Tuple2 (A : S) (B : S) : S with type t = A.t * B.t

module type Convert = sig
  type underlying
  type t

  val t_of_underlying : underlying -> t
  val underlying_of_t : t -> underlying
  val to_string_for_testing : [ `Use_underlying | `Custom of t -> string ]
end

module Iso (U : S) (C : Convert with type underlying := U.t) : S with type t = C.t
