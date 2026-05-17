defmodule Theoria.Lean.EncodeTest do
  use ExUnit.Case, async: true

  alias Theoria.Lean.Corpus
  alias Theoria.Lean.Encode
  alias Theoria.Lean.Module, as: LeanModule

  import Theoria.Term

  test "encodes dependent identity terms" do
    type = forall(:a, sort(1), arrow(bvar(0), bvar(0)))
    proof = lam(:a, sort(1), lam(:x, bvar(0), bvar(0)))

    assert Encode.term(type) == "(forall (a : Type), (a -> a))"
    assert Encode.term(proof) == "(fun (a : Type) => (fun (x : a) => x))"
  end

  test "encodes equality recursor through the oracle helper" do
    term =
      eq_rec(const(:Nat), lam(:n, const(:Nat), const(:Nat)), const(:zero), refl(const(:zero)))

    assert Encode.term(term) == "(tEqRec (fun (n : Nat) => Nat) Nat.zero rfl)"
  end

  test "renders the initial oracle corpus" do
    assert {:ok, lean_module, stats} = Corpus.build()
    source = LeanModule.render(lean_module)

    assert stats == %{proof: 28, defeq: 12, total: 40}
    assert source =~ "def tEqRec"
    assert source =~ "proof Theoria.Library.Equality.Theorems.eq_symm"
    assert source =~ "proof Theoria.Library.Bool.Theorems.bool_not_true"
    assert source =~ "proof Theoria.Library.Nat.Theorems.nat_add_two_zero"
    assert source =~ "defeq nat_add_one_zero"
  end

  test "encodes theorem proof checks" do
    proof = lam(:a, sort(1), lam(:x, bvar(0), bvar(0)))
    type = forall(:a, sort(1), arrow(bvar(0), bvar(0)))

    source =
      LeanModule.new()
      |> LeanModule.add_proof_check("identity", proof, type)
      |> LeanModule.render()

    assert source =~
             "example : (forall (a : Type), (a -> a)) := (fun (a : Type) => (fun (x : a) => x))"
  end
end
