defmodule Theoria.Equation.Context do
  @moduledoc "Experimental before 1.0; the shape may change. Internal named values available while materializing an equation branch body."

  alias Theoria.Term

  @enforce_keys [:vars, :outer]
  defstruct [
    :vars,
    :outer,
    :ih,
    :pred,
    :n,
    :head,
    :tail,
    :x,
    :xs,
    :a,
    :b,
    :element_type,
    :length
  ]

  @type t :: %__MODULE__{
          vars: %{optional(atom()) => Term.t()},
          outer: %{optional(atom()) => Term.t()},
          ih: Term.t() | nil,
          pred: Term.t() | nil,
          n: Term.t() | nil,
          head: Term.t() | nil,
          tail: Term.t() | nil,
          x: Term.t() | nil,
          xs: Term.t() | nil,
          a: Term.t() | nil,
          b: Term.t() | nil,
          element_type: Term.t() | nil,
          length: Term.t() | nil
        }

  @doc "Builds a context from branch variables and outer values."
  @spec new(map(), map()) :: t()
  def new(vars \\ %{}, outer \\ %{}) when is_map(vars) and is_map(outer) do
    values = Map.merge(vars, outer)

    %__MODULE__{
      vars: vars,
      outer: outer,
      ih: Map.get(values, :ih),
      pred: Map.get(values, :pred),
      n: Map.get(values, :n),
      head: Map.get(values, :head),
      tail: Map.get(values, :tail),
      x: Map.get(values, :x),
      xs: Map.get(values, :xs),
      a: Map.get(values, :a),
      b: Map.get(values, :b),
      element_type: Map.get(values, :element_type),
      length: Map.get(values, :length)
    }
  end

  @doc "Returns a named branch or outer value from an equation body context."
  @spec fetch!(t(), atom()) :: Term.t()
  def fetch!(%__MODULE__{} = context, name) do
    case {Map.fetch(context.vars, name), Map.fetch(context.outer, name)} do
      {{:ok, value}, _outer} -> value
      {:error, {:ok, value}} -> value
      {:error, :error} -> raise KeyError, key: name, term: context
    end
  end

  @doc "Returns a named branch variable."
  @spec var!(t(), atom()) :: Term.t()
  def var!(%__MODULE__{} = context, name), do: Map.fetch!(context.vars, name)

  @doc "Returns a named outer value captured by the branch."
  @spec outer!(t(), atom()) :: Term.t()
  def outer!(%__MODULE__{} = context, name), do: Map.fetch!(context.outer, name)
end
