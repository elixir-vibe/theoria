defmodule Theoria.Term.PropertyTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Theoria.Term

  import Theoria.Term

  property "shifting by zero is identity" do
    check all(term <- term_gen()) do
      assert Term.shift(term, 0) == term
    end
  end

  property "substitution with an out-of-range index is identity for closed terms" do
    check all(term <- closed_term_gen()) do
      assert Term.subst(term, 100, const(:replacement)) == term
    end
  end

  property "subst_top agrees with explicit shift-subst-shift sequence" do
    check all(body <- term_gen(), replacement <- closed_term_gen()) do
      explicit =
        body
        |> Term.subst(0, Term.shift(replacement, 1))
        |> Term.shift(-1)

      assert Term.subst_top(body, replacement) == explicit
    end
  end

  property "positive shifting composes additively" do
    check all(term <- term_gen(), left <- integer(0..3), right <- integer(0..3)) do
      assert term |> Term.shift(left) |> Term.shift(right) == Term.shift(term, left + right)
    end
  end

  defp term_gen do
    term_gen(3, 0)
  end

  defp closed_term_gen do
    term_gen(3, 0)
  end

  defp term_gen(0, depth) do
    leaf_gen(depth)
  end

  defp term_gen(size, depth) do
    smaller = term_gen(size - 1, depth)
    under_binder = term_gen(size - 1, depth + 1)

    one_of([
      leaf_gen(depth),
      map({smaller, smaller}, fn {fun, arg} -> app(fun, arg) end),
      map({smaller, smaller, smaller}, fn {type, left, right} -> eq(type, left, right) end),
      map(smaller, &refl/1),
      map({leaf_gen(depth), under_binder}, fn {domain, body} -> lam(:x, domain, body) end),
      map({leaf_gen(depth), under_binder}, fn {domain, body} -> forall(:x, domain, body) end)
    ])
  end

  defp leaf_gen(0) do
    one_of([
      map(integer(0..2), &sort/1),
      map(member_of([:a, :b, :c]), &const/1)
    ])
  end

  defp leaf_gen(depth) when depth > 0 do
    one_of([
      map(integer(0..2), &sort/1),
      map(member_of([:a, :b, :c]), &const/1),
      map(integer(0..(depth - 1)), &bvar/1)
    ])
  end
end
