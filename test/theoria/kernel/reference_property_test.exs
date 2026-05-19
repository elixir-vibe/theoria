defmodule Theoria.Kernel.ReferencePropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Theoria.Kernel
  alias Theoria.Kernel.Reference
  alias Theoria.Kernel.Reference.Normalize, as: ReferenceNormalize
  alias Theoria.Normalize
  alias Theoria.Prelude
  alias Theoria.Term

  property "production and reference agree on generated Bool terms" do
    check all(term <- bool_term_gen()) do
      {:ok, env} = Prelude.env()
      bool = Term.const(:Bool)

      assert Kernel.infer(env, term) == Reference.infer(env, term)
      assert Kernel.check(env, term, bool) == Reference.check(env, term, bool)
    end
  end

  property "production and reference agree on generated Bool equalities" do
    check all(term <- bool_term_gen()) do
      {:ok, env} = Prelude.env()
      bool = Term.const(:Bool)
      equality = Term.eq(bool, term, term)
      proof = Term.refl(term)

      assert Kernel.infer(env, equality) == Reference.infer(env, equality)
      assert Kernel.check(env, proof, equality) == Reference.check(env, proof, equality)
    end
  end

  property "production and reference normalization agree on generated Bool terms" do
    check all(term <- bool_term_gen()) do
      {:ok, env} = Prelude.env()

      assert Normalize.normalize(env, term) == ReferenceNormalize.normalize(env, term)
    end
  end

  property "production and reference agree on generated Nat terms" do
    check all(term <- nat_term_gen()) do
      {:ok, env} = Prelude.env()
      nat = Term.const(:Nat)

      assert Kernel.infer(env, term) == Reference.infer(env, term)
      assert Kernel.check(env, term, nat) == Reference.check(env, term, nat)
    end
  end

  property "production and reference agree on generated Nat equalities" do
    check all(term <- nat_term_gen()) do
      {:ok, env} = Prelude.env()
      nat = Term.const(:Nat)
      equality = Term.eq(nat, term, term)
      proof = Term.refl(term)

      assert Kernel.infer(env, equality) == Reference.infer(env, equality)
      assert Kernel.check(env, proof, equality) == Reference.check(env, proof, equality)
    end
  end

  property "production and reference normalization agree on generated Nat terms" do
    check all(term <- nat_term_gen()) do
      {:ok, env} = Prelude.env()

      assert Normalize.normalize(env, term) == ReferenceNormalize.normalize(env, term)
    end
  end

  defp bool_term_gen do
    bool_term_gen(3)
  end

  defp bool_term_gen(0) do
    leaf_bool_gen()
  end

  defp bool_term_gen(size) do
    smaller = bool_term_gen(size - 1)

    one_of([
      leaf_bool_gen(),
      map(smaller, &Term.app(Term.const(:bool_not), &1)),
      map({smaller, smaller}, fn {left, right} ->
        Term.app(Term.app(Term.const(:bool_and), left), right)
      end),
      map({smaller, smaller}, fn {left, right} ->
        Term.app(Term.app(Term.const(:bool_or), left), right)
      end),
      map(smaller, fn value -> Term.let(:b, Term.const(:Bool), value, Term.bvar(0)) end)
    ])
  end

  defp leaf_bool_gen do
    member_of([Term.const(true), Term.const(false)])
  end

  defp nat_term_gen do
    nat_term_gen(3)
  end

  defp nat_term_gen(0) do
    leaf_nat_gen()
  end

  defp nat_term_gen(size) do
    smaller = nat_term_gen(size - 1)

    one_of([
      leaf_nat_gen(),
      map(smaller, &Term.app(Term.const(:succ), &1)),
      map({smaller, smaller}, fn {left, right} ->
        Term.app(Term.app(Term.const(:nat_add), left), right)
      end),
      map(smaller, fn value -> Term.let(:n, Term.const(:Nat), value, Term.bvar(0)) end)
    ])
  end

  defp leaf_nat_gen do
    member_of([Term.const(:zero), Term.app(Term.const(:succ), Term.const(:zero))])
  end
end
