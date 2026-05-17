(List.length (@List.nil Nat))
(List.rec (motive := fun _ => Nat) Nat.zero (fun (x : Nat) => (fun (xs : (List Nat)) => (fun (acc : Nat) => (Nat.succ acc)))) (@List.nil Nat))
