inductive TVec (a : Type u) : Nat -> Type u where
  | vec_nil : (TVec a Nat.zero)
  | vec_cons : (x : a) -> (n : Nat) -> (x0 : (TVec a n)) -> (TVec a (Nat.succ n))
