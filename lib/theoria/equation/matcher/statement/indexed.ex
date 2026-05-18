defmodule Theoria.Equation.Matcher.Statement.Indexed do
  @moduledoc "Shared helpers for indexed matcher statement planning."

  alias Theoria.Equation.Matcher.Statement.Frame
  alias Theoria.Term

  @doc "Returns the binder telescope common to indexed matcher equations."
  @spec statement_binders(term()) :: [{atom(), Term.t()}]
  def statement_binders(shape) do
    shape.parameters ++
      [{shape.motive_name, shape.motive_type}] ++
      shape.index_binders ++ shape.discriminant_binders ++ shape.alternative_binders
  end

  @doc "Returns references to named binders in order."
  @spec refs_for_names(Frame.t(), [atom()]) :: {:ok, [Term.t()]} | {:error, term()}
  def refs_for_names(frame, names) do
    names
    |> Enum.reduce_while({:ok, []}, fn name, {:ok, refs} ->
      case Frame.ref(frame, name) do
        {:ok, ref} -> {:cont, {:ok, [ref | refs]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, refs} -> {:ok, Enum.reverse(refs)}
      {:error, _reason} = error -> error
    end
  end

  @doc "Applies arguments left-to-right to a function term."
  @spec apply_args(Term.t(), [Term.t()]) :: Term.t()
  def apply_args(function, arguments) do
    Enum.reduce(arguments, function, fn argument, term -> Term.app(term, argument) end)
  end

  @doc "Derives current statement levels from parameter sorts."
  @spec statement_levels(term()) :: [term()]
  def statement_levels(shape) do
    shape.parameters
    |> Keyword.values()
    |> Enum.find_value([1], fn
      %Term.Sort{level: level} -> [level]
      _type -> false
    end)
  end

  @doc "Collects a forall telescope into `{name, domain}` pairs."
  @spec collect_foralls(Term.t()) :: [{atom(), Term.t()}]
  def collect_foralls(%Term.Forall{name: name, domain: domain, body: body}) do
    [{name, domain} | collect_foralls(body)]
  end

  def collect_foralls(_body), do: []
end
