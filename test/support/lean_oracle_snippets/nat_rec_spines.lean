(Nat.rec Nat.zero (fun (x : Nat) => (fun (acc : Nat) => (Nat.succ acc))) Nat.zero)
(Nat.rec (motive := (fun (n : Nat) => Nat)) Nat.zero (fun (n : Nat) => (fun (ih : Nat) => (Nat.succ ih))) Nat.zero)
