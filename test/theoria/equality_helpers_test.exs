defmodule Theoria.EqualityHelpersTest do
  use ExUnit.Case, async: true

  alias Theoria.Equality
  alias Theoria.Kernel
  alias Theoria.Library.Nat
  alias Theoria.Normalize

  import Theoria.Term

  test "rewrite builds an equality recursor" do
    term =
      Equality.rewrite(
        const(:Nat),
        lam(:n, const(:Nat), const(:Nat)),
        const(:zero),
        refl(const(:zero))
      )

    assert term ==
             eq_rec(
               const(:Nat),
               lam(:n, const(:Nat), const(:Nat)),
               const(:zero),
               refl(const(:zero))
             )
  end

  test "subst transports a motive across equality" do
    {:ok, env} = Nat.env()

    term =
      Equality.subst(
        const(:Nat),
        lam(:n, const(:Nat), eq(const(:Nat), bvar(0), bvar(0))),
        refl(const(:zero)),
        refl(const(:zero))
      )

    assert Kernel.check(env, term, eq(const(:Nat), const(:zero), const(:zero))) == :ok
    assert Normalize.normalize(env, term) == {:ok, refl(const(:zero))}
  end

  test "ndrec builds constant-motive equality transport" do
    {:ok, env} = Nat.env()

    term = Equality.ndrec(const(:Nat), const(:Nat), const(:zero), refl(const(:zero)))

    assert Kernel.check(env, term, const(:Nat)) == :ok
    assert Normalize.normalize(env, term) == {:ok, const(:zero)}
  end
end
