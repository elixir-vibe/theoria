defmodule Theoria.Equation.Matcher.Statement.Frame do
  @moduledoc "Internal binder frame for matcher equation statement planning."

  alias Theoria.Term

  @type binder :: {atom(), Term.t()}
  @type t :: %__MODULE__{binders: [binder()]}

  @enforce_keys [:binders]
  defstruct [:binders]

  @spec new([binder()]) :: t()
  def new(binders), do: %__MODULE__{binders: binders}

  @spec push(t(), atom(), Term.t()) :: t()
  def push(%__MODULE__{binders: binders}, name, type),
    do: %__MODULE__{binders: binders ++ [{name, type}]}

  @spec push_many(t(), [binder()]) :: t()
  def push_many(frame, binders) do
    Enum.reduce(binders, frame, fn {name, type}, acc -> push(acc, name, type) end)
  end

  @spec binders(t()) :: [binder()]
  def binders(%__MODULE__{binders: binders}), do: binders

  @spec fetch(t(), atom()) :: {:ok, {binder(), non_neg_integer()}} | {:error, term()}
  def fetch(%__MODULE__{binders: binders}, name) do
    binders
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.find(&(elem(elem(&1, 0), 0) == name))
    |> case do
      {{_name, _type} = binder, index} -> {:ok, {binder, index}}
      nil -> {:error, {:unknown_indexed_matcher_statement_binder, name}}
    end
  end

  @spec ref(t(), atom()) :: {:ok, Term.BVar.t()} | {:error, term()}
  def ref(%__MODULE__{} = frame, name) do
    case fetch(frame, name) do
      {:ok, {_binder, index}} -> {:ok, Term.bvar(index)}
      {:error, _reason} = error -> error
    end
  end

  @spec ref!(t(), atom()) :: Term.BVar.t()
  def ref!(%__MODULE__{} = frame, name) do
    case ref(frame, name) do
      {:ok, ref} -> ref
      {:error, reason} -> raise ArgumentError, inspect(reason)
    end
  end

  @spec forall(t(), Term.t()) :: Term.t()
  def forall(%__MODULE__{} = frame, body), do: forall_telescope(binders(frame), body)

  defp forall_telescope(binders, result) do
    Enum.reduce(Enum.reverse(binders), result, fn {name, type}, body ->
      Term.forall(name, type, body)
    end)
  end
end
