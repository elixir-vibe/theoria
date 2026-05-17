defmodule Theoria.Validation.SmallTerms do
  @moduledoc "Deterministic small normalized-term checks owned by Theoria validation."

  alias Theoria.Normalize
  alias Theoria.Prelude
  alias Theoria.Term
  alias Theoria.Validation.DefeqCheck
  alias Theoria.Validation.Terms

  @doc "Returns small definitional-equality checks whose right side is Theoria-normalized."
  @spec defeq_checks() :: [DefeqCheck.t()]
  def defeq_checks do
    {:ok, env} = Prelude.env()

    [bool_terms(), nat_terms(), list_terms(), vec_terms()]
    |> List.flatten()
    |> Enum.map(fn {category, name, left} ->
      DefeqCheck.new(category, name, left, normalize!(env, left))
    end)
  end

  defp bool_terms do
    bool_true = Term.const(true)
    bool_false = Term.const(false)

    [
      {:bool, "small_bool_not_true", Term.app(Term.const(:bool_not), bool_true)},
      {:bool, "small_bool_not_false", Term.app(Term.const(:bool_not), bool_false)},
      {:bool, "small_bool_and_true_true",
       Term.const(:bool_and) |> Term.app(bool_true) |> Term.app(bool_true)},
      {:bool, "small_bool_and_false_true",
       Term.const(:bool_and) |> Term.app(bool_false) |> Term.app(bool_true)},
      {:bool, "small_bool_or_false_false",
       Term.const(:bool_or) |> Term.app(bool_false) |> Term.app(bool_false)},
      {:bool, "small_bool_or_true_false",
       Term.const(:bool_or) |> Term.app(bool_true) |> Term.app(bool_false)}
    ]
  end

  defp nat_terms do
    zero = Term.const(:zero)
    one = Term.app(Term.const(:succ), zero)
    two = Term.app(Term.const(:succ), one)
    naturals = [{"zero", zero}, {"one", one}, {"two", two}]

    add =
      for {left_name, left} <- naturals,
          {right_name, right} <- naturals do
        {:nat, "small_nat_add_#{left_name}_#{right_name}",
         Term.const(:nat_add) |> Term.app(left) |> Term.app(right)}
      end

    rec =
      for {name, value} <- naturals do
        {:nat, "small_nat_rec_#{name}",
         Term.const(:nat_rec)
         |> Term.app(Term.const(:Nat))
         |> Term.app(zero)
         |> Term.app(Terms.nat_succ_case())
         |> Term.app(value)}
      end

    add ++ rec
  end

  defp list_terms do
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    one = Term.app(Term.const(:succ), zero)
    empty = Term.app(Term.const(:list_nil), nat)
    singleton = Term.const(:list_cons) |> Term.app(nat) |> Term.app(zero) |> Term.app(empty)
    pair = Term.const(:list_cons) |> Term.app(nat) |> Term.app(one) |> Term.app(singleton)

    for {name, list} <- [{"nil", empty}, {"singleton", singleton}, {"pair", pair}] do
      {:list, "small_list_length_#{name}",
       Term.const(:list_length) |> Term.app(nat) |> Term.app(list)}
    end
  end

  defp vec_terms do
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    one = Term.app(Term.const(:succ), zero)
    empty = Term.app(Term.const(:vec_nil), nat)

    singleton =
      Term.const(:vec_cons)
      |> Term.app(nat)
      |> Term.app(zero)
      |> Term.app(zero)
      |> Term.app(empty)

    [
      {:vec, "small_vec_ind_nil", vec_ind(zero, empty)},
      {:vec, "small_vec_ind_singleton", vec_ind(one, singleton)}
    ]
  end

  defp vec_ind(index, vector) do
    Term.const(:vec_ind)
    |> Term.app(Term.const(:Nat))
    |> Term.app(Terms.vec_nat_motive())
    |> Term.app(Term.const(:zero))
    |> Term.app(Terms.vec_succ_case())
    |> Term.app(index)
    |> Term.app(vector)
  end

  defp normalize!(env, term) do
    case Normalize.normalize(env, term) do
      {:ok, normalized} -> normalized
      {:error, error} -> raise "failed to normalize validation term: #{inspect(error)}"
    end
  end
end
