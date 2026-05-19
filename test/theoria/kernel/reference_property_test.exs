defmodule Theoria.Kernel.ReferencePropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Theoria.Kernel
  alias Theoria.Kernel.GeneratedTerm
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

  property "production and reference agree on generated List Bool terms" do
    check all(term <- list_bool_term_gen()) do
      {:ok, env} = Prelude.env()
      list_bool = Term.app(Term.const(:List, [1]), Term.const(:Bool))

      assert Kernel.infer(env, term) == Reference.infer(env, term)
      assert Kernel.check(env, term, list_bool) == Reference.check(env, term, list_bool)
    end
  end

  property "production and reference normalization agree on generated List Bool terms" do
    check all(term <- list_bool_term_gen()) do
      {:ok, env} = Prelude.env()

      assert Normalize.normalize(env, term) == ReferenceNormalize.normalize(env, term)
    end
  end

  property "production and reference normalization agree on generated List Bool eliminators" do
    check all(left <- list_bool_term_gen(), right <- list_bool_term_gen()) do
      {:ok, env} = Prelude.env()
      bool = Term.const(:Bool)

      length = Term.app(Term.app(Term.const(:list_length, [1]), bool), left)
      append = Term.app(Term.app(Term.app(Term.const(:list_append, [1]), bool), left), right)

      assert Normalize.normalize(env, length) == ReferenceNormalize.normalize(env, length)
      assert Normalize.normalize(env, append) == ReferenceNormalize.normalize(env, append)
    end
  end

  property "production and reference agree on generated Vec Bool terms" do
    check all({term, index} <- vec_bool_term_gen()) do
      {:ok, env} = Prelude.env()
      type = vec_bool_type(index)

      assert Kernel.infer(env, term) == Reference.infer(env, term)
      assert Kernel.check(env, term, type) == Reference.check(env, term, type)
    end
  end

  property "production and reference agree on generated Vec Bool equalities" do
    check all({term, index} <- vec_bool_term_gen()) do
      {:ok, env} = Prelude.env()
      type = vec_bool_type(index)
      equality = Term.eq(type, term, term)
      proof = Term.refl(term)

      assert Kernel.infer(env, equality) == Reference.infer(env, equality)
      assert Kernel.check(env, proof, equality) == Reference.check(env, proof, equality)
    end
  end

  property "production and reference agree on typed generated dependent terms" do
    check all(%GeneratedTerm{env: env, term: term, type: type} <- typed_dependent_term_gen()) do
      assert Kernel.infer(env, term) == Reference.infer(env, term)
      assert Kernel.check(env, term, type) == Reference.check(env, term, type)
    end
  end

  property "production and reference normalization agree on generated Vec Bool terms" do
    check all({term, _index} <- vec_bool_term_gen()) do
      {:ok, env} = Prelude.env()

      assert Normalize.normalize(env, term) == ReferenceNormalize.normalize(env, term)
    end
  end

  defp typed_dependent_term_gen do
    {:ok, env} = Prelude.env()
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)

    one_of([
      map(bool_term_gen(), fn term -> GeneratedTerm.new(env, term, bool) end),
      map(nat_term_gen(), fn term -> GeneratedTerm.new(env, term, nat) end),
      map(bool_term_gen(), fn term ->
        type = Term.arrow(bool, bool)
        GeneratedTerm.new(env, Term.lam(:x, bool, Term.shift(term, 1)), type)
      end),
      map(nat_term_gen(), fn term ->
        equality = Term.eq(nat, term, term)
        GeneratedTerm.new(env, Term.refl(term), equality)
      end),
      map(nat_term_gen(), fn term ->
        motive = Term.lam(:n, nat, Term.shift(nat, 1))
        base = term
        proof = Term.refl(term)
        GeneratedTerm.new(env, Term.eq_rec(nat, motive, base, proof), nat)
      end)
    ])
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

  defp list_bool_term_gen do
    list_bool_term_gen(3)
  end

  defp list_bool_term_gen(0) do
    leaf_list_bool_gen()
  end

  defp list_bool_term_gen(size) do
    smaller = list_bool_term_gen(size - 1)

    one_of([
      leaf_list_bool_gen(),
      map({bool_term_gen(), smaller}, fn {head, tail} -> list_cons_bool(head, tail) end),
      map(smaller, fn value ->
        list_bool = Term.app(Term.const(:List, [1]), Term.const(:Bool))
        Term.let(:xs, list_bool, value, Term.bvar(0))
      end)
    ])
  end

  defp leaf_list_bool_gen do
    constant(empty_list_bool())
  end

  defp empty_list_bool do
    Term.app(Term.const(:list_nil, [1]), Term.const(:Bool))
  end

  defp list_cons_bool(head, tail) do
    Term.app(Term.app(Term.app(Term.const(:list_cons, [1]), Term.const(:Bool)), head), tail)
  end

  defp vec_bool_term_gen do
    vec_bool_term_gen(3)
  end

  defp vec_bool_term_gen(0) do
    constant({empty_vec_bool(), Term.const(:zero)})
  end

  defp vec_bool_term_gen(size) do
    smaller = vec_bool_term_gen(size - 1)

    one_of([
      vec_bool_term_gen(0),
      map({bool_term_gen(), smaller}, fn {head, {tail, index}} ->
        {vec_cons_bool(head, index, tail), Term.app(Term.const(:succ), index)}
      end),
      map(smaller, fn {value, index} ->
        Term.let(:xs, vec_bool_type(index), value, Term.bvar(0))
        |> then(&{&1, index})
      end)
    ])
  end

  defp vec_bool_type(index) do
    Term.app(Term.app(Term.const(:Vec, [1]), Term.const(:Bool)), index)
  end

  defp empty_vec_bool do
    Term.app(Term.const(:vec_nil, [1]), Term.const(:Bool))
  end

  defp vec_cons_bool(head, index, tail) do
    Term.app(
      Term.app(Term.app(Term.app(Term.const(:vec_cons, [1]), Term.const(:Bool)), head), index),
      tail
    )
  end
end
