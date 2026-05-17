defmodule Theoria.Lean.EncodeTest do
  use ExUnit.Case, async: true

  alias Theoria.Lean.Corpus
  alias Theoria.Lean.Encodable
  alias Theoria.Lean.Encode
  alias Theoria.Lean.Module, as: LeanModule

  import Theoria.Term

  test "encodes dependent identity terms" do
    type = forall(:a, sort(1), arrow(bvar(0), bvar(0)))
    proof = lam(:a, sort(1), lam(:x, bvar(0), bvar(0)))

    assert Encode.term(type) == "(forall (a : Type), (a -> a))"
    assert Encode.term(proof) == "(fun (a : Type) => (fun (x : a) => x))"
  end

  test "protocol dispatch encodes each core term shape" do
    assert Encodable.encode(sort(1), []) == "Type"
    assert Encodable.encode(const(:Nat), []) == "Nat"
    assert Encodable.encode(bvar(0), ["x"]) == "x"
    assert Encodable.encode(app(const(:succ), const(:zero)), []) == "(Nat.succ Nat.zero)"
    assert Encodable.encode(lam(:x, const(:Nat), bvar(0)), []) == "(fun (x : Nat) => x)"
    assert Encodable.encode(forall(:x, const(:Nat), const(:Nat)), []) == "(forall (x : Nat), Nat)"

    assert Encodable.encode(let(:x, const(:Nat), const(:zero), bvar(0)), []) ==
             "(let x : Nat := Nat.zero; x)"

    assert Encodable.encode(eq(const(:Nat), const(:zero), const(:zero)), []) ==
             "(Nat.zero = Nat.zero)"

    assert Encodable.encode(refl(const(:zero)), []) == "rfl"
  end

  test "encodes equality recursor through the oracle helper" do
    term =
      eq_rec(const(:Nat), lam(:n, const(:Nat), const(:Nat)), const(:zero), refl(const(:zero)))

    assert Encode.term(term) == "(tEqRec (fun (n : Nat) => Nat) Nat.zero rfl)"
  end

  test "encodes special recursor application spines" do
    bool_rec =
      const(:bool_rec)
      |> app(const(:Bool))
      |> app(const(true))
      |> app(const(false))
      |> app(const(true))

    nat_rec =
      const(:nat_rec)
      |> app(const(:Nat))
      |> app(const(:zero))
      |> app(nat_succ_case())
      |> app(const(:zero))

    nat_ind =
      const(:nat_ind)
      |> app(lam(:n, const(:Nat), const(:Nat)))
      |> app(const(:zero))
      |> app(nat_ind_succ_case())
      |> app(const(:zero))

    list_length =
      const(:list_length) |> app(const(:Nat)) |> app(app(const(:list_nil), const(:Nat)))

    assert Encode.term(bool_rec) ==
             "(match Bool.true with | Bool.true => Bool.true | Bool.false => Bool.false)"

    assert Encode.term(nat_rec) =~ "Nat.rec Nat.zero"
    assert Encode.term(nat_ind) =~ "Nat.rec (motive := (fun (n : Nat) => Nat))"
    assert Encode.term(list_length) == "(List.length (@List.nil Nat))"
  end

  test "renders the initial oracle corpus" do
    assert {:ok, lean_module, stats} = Corpus.build()
    source = LeanModule.render(lean_module)

    assert stats == %{proof: 51, defeq: 41, total: 92}
    assert source =~ "def tEqRec"
    assert source =~ "proof Theoria.Library.Logic.Theorems.and_comm"
    assert source =~ "proof Theoria.Library.Equality.Theorems.eq_symm"
    assert source =~ "proof Theoria.Library.Bool.Theorems.bool_not_true"
    assert source =~ "proof Theoria.Library.Nat.Theorems.nat_add_two_zero"
    assert source =~ "proof Theoria.Library.List.Theorems.list_length_two"
    assert source =~ "proof Theoria.Library.Vec.Theorems.vec_ind_cons_nat"
    assert source =~ "defeq nat_add_one_zero"
    assert source =~ "defeq list_length_singleton"
    assert source =~ "defeq vec_ind_cons"
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

  test "filters oracle corpus categories" do
    assert {:ok, _lean_module, stats} = Corpus.build(only: [:bool])
    assert stats == %{proof: 15, defeq: 12, total: 27}

    assert {:ok, _lean_module, stats} = Corpus.build(only: [:defeq])
    assert stats == %{proof: 0, defeq: 41, total: 41}
  end

  defp nat_succ_case do
    lam(:_pred, const(:Nat), lam(:acc, const(:Nat), app(const(:succ), bvar(0))))
  end

  defp nat_ind_succ_case do
    lam(:n, const(:Nat), lam(:ih, const(:Nat), app(const(:succ), bvar(0))))
  end
end
