open! Core
include Backend_intf

module Map_backend = struct
  type t = string String.Map.t ref

  let create ~path:_ = ref String.Map.empty
  let put t ~key ~data = Ref.replace t (fun t -> Map.set t ~key ~data)
  let get t key = Map.find !t key
  let delete t key = Ref.replace t (fun t -> Map.remove t key)

  module Iter = struct
    type t = (string * string) Sequence.t ref

    let get t = Sequence.hd !t

    let next t =
      match Sequence.tl !t with
      | None -> t := Sequence.empty
      | Some x -> t := x
    ;;

    let is_valid t = not (Sequence.is_empty !t)
  end

  let iterate ?seek_to t =
    match seek_to with
    | None -> ref (Map.to_sequence !t)
    | Some seek_to -> ref (Map.to_sequence ~keys_greater_or_equal_to:seek_to !t)
  ;;
end
