open! Core

module type S = sig
  type t

  val size : t -> int
  val to_bytes : t -> (read_write, Iobuf.seek) Iobuf.t -> unit
  val of_bytes : (read_write, Iobuf.seek) Iobuf.t -> t
  val to_string_for_testing : t -> string
end

module Int64 = struct
  type t = int

  let size _ = 8
  let to_bytes i buf = Iobuf.Fill.int64_be buf i
  let of_bytes buf = Iobuf.Consume.int64_be_exn buf
  let to_string_for_testing = Int.to_string
end

module Int63 = struct
  type t = Int63.t

  let size _ = 8
  let to_bytes i buf = Iobuf.Fill.int64_t_be buf (Int63.to_int64 i)
  let of_bytes buf = Iobuf.Consume.int64_t_be buf |> Int63.of_int64_exn
  let to_string_for_testing = Int63.to_string
end

module Int32 = struct
  type t = int

  let size _ = 4
  let to_bytes i buf = Iobuf.Fill.int32_be_trunc buf i
  let of_bytes buf = Iobuf.Consume.int32_be buf
  let to_string_for_testing = Int.to_string
end

module Int16 = struct
  type t = int

  let size _ = 2
  let to_bytes i buf = Iobuf.Fill.int16_be_trunc buf i
  let of_bytes buf = Iobuf.Consume.int16_be buf
  let to_string_for_testing = Int.to_string
end

module Int8 = struct
  type t = int

  let size _ = 1
  let to_bytes i buf = Iobuf.Fill.int8_trunc buf i
  let of_bytes buf = Iobuf.Consume.int8 buf
  let to_string_for_testing = Int.to_string
end

module Uint32 = struct
  type t = int

  let size _ = 4
  let to_bytes i buf = Iobuf.Fill.uint32_be_trunc buf i
  let of_bytes buf = Iobuf.Consume.uint32_be buf
  let to_string_for_testing = Int.to_string
end

module Uint16 = struct
  type t = int

  let size _ = 2
  let to_bytes i buf = Iobuf.Fill.uint16_be_trunc buf i
  let of_bytes buf = Iobuf.Consume.uint16_be buf
  let to_string_for_testing = Int.to_string
end

module Uint8 = struct
  type t = int

  let size _ = 1
  let to_bytes i buf = Iobuf.Fill.uint8_trunc buf i
  let of_bytes buf = Iobuf.Consume.uint8 buf
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

module Tuple2 (A : S) (B : S) = struct
  type t = A.t * B.t

  let size (a, b) = A.size a + B.size b + 1

  let to_bytes (a, b) iobuf =
    A.to_bytes a iobuf;
    Iobuf.Fill.uint8_trunc iobuf 0;
    B.to_bytes b iobuf
  ;;

  let of_bytes iobuf =
    let a = A.of_bytes iobuf in
    let (_ : int) = Iobuf.Consume.int8 iobuf in
    let b = B.of_bytes iobuf in
    a, b
  ;;

  let to_string_for_testing (a, b) =
    sprintf "(%s, %s)" (A.to_string_for_testing a) (B.to_string_for_testing b)
  ;;
end

module type Convert = sig
  type underlying
  type t

  val t_of_underlying : underlying -> t
  val underlying_of_t : t -> underlying
  val to_string_for_testing : [ `Use_underlying | `Custom of t -> string ]
end

module Iso (U : S) (C : Convert with type underlying := U.t) = struct
  type t = C.t

  let size t = U.size (C.underlying_of_t t)
  let to_bytes t iobuf = U.to_bytes (C.underlying_of_t t) iobuf
  let of_bytes iobuf = U.of_bytes iobuf |> C.t_of_underlying

  let to_string_for_testing =
    match C.to_string_for_testing with
    | `Use_underlying -> fun t -> U.to_string_for_testing (C.underlying_of_t t)
    | `Custom f -> f
  ;;
end

module Time_sec =
  Iso
    (Uint32)
    (struct
      type t = Time_ns.t

      let t_of_underlying v = Time_ns.of_span_since_epoch (Time_ns.Span.of_int_sec v)
      let underlying_of_t t = t |> Time_ns.to_span_since_epoch |> Time_ns.Span.to_int_sec
      let to_string_for_testing = `Use_underlying
    end)

module Time_sec_span =
  Iso
    (Uint32)
    (struct
      type t = Time_ns.Span.t

      let t_of_underlying = Time_ns.Span.of_int_sec
      let underlying_of_t = Time_ns.Span.to_int_sec
      let to_string_for_testing = `Use_underlying
    end)

module Time_ns_span =
  Iso
    (Int63)
    (struct
      type t = Time_ns.Span.t

      let t_of_underlying = Time_ns.Span.of_int63_ns
      let underlying_of_t = Time_ns.Span.to_int63_ns
      let to_string_for_testing = `Use_underlying
    end)

module Time_ns =
  Iso
    (Int63)
    (struct
      type t = Time_ns.t

      let t_of_underlying = Time_ns.of_int63_ns_since_epoch
      let underlying_of_t = Time_ns.to_int63_ns_since_epoch
      let to_string_for_testing = `Use_underlying
    end)
