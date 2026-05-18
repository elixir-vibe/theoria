defmodule Theoria.Rewrite.Match do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Untrusted first-order matching for schematic rewrite rules."

  alias Theoria.Term

  @type substitution :: %{non_neg_integer() => Term.t()}

  @doc "Matches `pattern` against `term`, treating low de Bruijn variables as metavariables."
  @spec match(Term.t(), Term.t(), non_neg_integer()) :: {:ok, substitution()} | :error
  def match(pattern, term, binder_count) when is_integer(binder_count) and binder_count >= 0 do
    match_term(pattern, term, binder_count, %{})
  end

  @doc "Instantiates low de Bruijn variables in a template using a substitution."
  @spec instantiate(Term.t(), substitution()) :: Term.t()
  def instantiate(term, substitution), do: instantiate_term(term, substitution)

  defp match_term(%Term.BVar{index: index}, term, binder_count, substitution)
       when index < binder_count do
    case Map.fetch(substitution, index) do
      {:ok, ^term} -> {:ok, substitution}
      {:ok, _other} -> :error
      :error -> {:ok, Map.put(substitution, index, term)}
    end
  end

  defp match_term(%Term.Sort{} = pattern, %Term.Sort{} = term, _binder_count, substitution)
       when pattern == term,
       do: {:ok, substitution}

  defp match_term(%Term.BVar{} = pattern, %Term.BVar{} = term, _binder_count, substitution)
       when pattern == term,
       do: {:ok, substitution}

  defp match_term(%Term.Const{} = pattern, %Term.Const{} = term, _binder_count, substitution)
       when pattern == term,
       do: {:ok, substitution}

  defp match_term(%Term.App{} = pattern, %Term.App{} = term, binder_count, substitution) do
    with {:ok, substitution} <- match_term(pattern.fun, term.fun, binder_count, substitution) do
      match_term(pattern.arg, term.arg, binder_count, substitution)
    end
  end

  defp match_term(%Term.Lam{} = pattern, %Term.Lam{} = term, binder_count, substitution) do
    with {:ok, substitution} <-
           match_term(pattern.domain, term.domain, binder_count, substitution) do
      match_term(pattern.body, term.body, binder_count, substitution)
    end
  end

  defp match_term(%Term.Forall{} = pattern, %Term.Forall{} = term, binder_count, substitution) do
    with {:ok, substitution} <-
           match_term(pattern.domain, term.domain, binder_count, substitution) do
      match_term(pattern.body, term.body, binder_count, substitution)
    end
  end

  defp match_term(%Term.Let{} = pattern, %Term.Let{} = term, binder_count, substitution) do
    with {:ok, substitution} <- match_term(pattern.type, term.type, binder_count, substitution),
         {:ok, substitution} <- match_term(pattern.value, term.value, binder_count, substitution) do
      match_term(pattern.body, term.body, binder_count, substitution)
    end
  end

  defp match_term(%Term.Eq{} = pattern, %Term.Eq{} = term, binder_count, substitution) do
    with {:ok, substitution} <- match_term(pattern.type, term.type, binder_count, substitution),
         {:ok, substitution} <- match_term(pattern.left, term.left, binder_count, substitution) do
      match_term(pattern.right, term.right, binder_count, substitution)
    end
  end

  defp match_term(%Term.Refl{} = pattern, %Term.Refl{} = term, binder_count, substitution) do
    match_term(pattern.value, term.value, binder_count, substitution)
  end

  defp match_term(%Term.EqRec{} = pattern, %Term.EqRec{} = term, binder_count, substitution) do
    with {:ok, substitution} <- match_term(pattern.type, term.type, binder_count, substitution),
         {:ok, substitution} <-
           match_term(pattern.motive, term.motive, binder_count, substitution),
         {:ok, substitution} <- match_term(pattern.base, term.base, binder_count, substitution) do
      match_term(pattern.proof, term.proof, binder_count, substitution)
    end
  end

  defp match_term(_pattern, _term, _binder_count, _substitution), do: :error

  defp instantiate_term(%Term.BVar{index: index} = term, substitution),
    do: Map.get(substitution, index, term)

  defp instantiate_term(%Term.App{} = term, substitution),
    do: %Term.App{
      term
      | fun: instantiate_term(term.fun, substitution),
        arg: instantiate_term(term.arg, substitution)
    }

  defp instantiate_term(%Term.Lam{} = term, substitution),
    do: %Term.Lam{
      term
      | domain: instantiate_term(term.domain, substitution),
        body: instantiate_term(term.body, substitution)
    }

  defp instantiate_term(%Term.Forall{} = term, substitution),
    do: %Term.Forall{
      term
      | domain: instantiate_term(term.domain, substitution),
        body: instantiate_term(term.body, substitution)
    }

  defp instantiate_term(%Term.Let{} = term, substitution) do
    %Term.Let{
      term
      | type: instantiate_term(term.type, substitution),
        value: instantiate_term(term.value, substitution),
        body: instantiate_term(term.body, substitution)
    }
  end

  defp instantiate_term(%Term.Eq{} = term, substitution),
    do: %Term.Eq{
      term
      | type: instantiate_term(term.type, substitution),
        left: instantiate_term(term.left, substitution),
        right: instantiate_term(term.right, substitution)
    }

  defp instantiate_term(%Term.Refl{} = term, substitution),
    do: %Term.Refl{term | value: instantiate_term(term.value, substitution)}

  defp instantiate_term(%Term.EqRec{} = term, substitution) do
    %Term.EqRec{
      term
      | type: instantiate_term(term.type, substitution),
        motive: instantiate_term(term.motive, substitution),
        base: instantiate_term(term.base, substitution),
        proof: instantiate_term(term.proof, substitution)
    }
  end

  defp instantiate_term(term, _substitution), do: term
end
