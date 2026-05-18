defmodule Theoria.Equation.Clause do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. A constructor equation clause."

  alias Theoria.Equation.Context
  alias Theoria.Equation.Pattern
  alias Theoria.Term

  @enforce_keys [:patterns, :body]
  defstruct [:patterns, :body, binders: []]

  @type body :: Term.t() | (Context.t() -> Term.t())
  @type t :: %__MODULE__{patterns: [Pattern.t()], body: body(), binders: [atom()]}

  @doc "Builds an equation clause."
  @spec new([Pattern.t()], body(), keyword()) :: t()
  def new(patterns, body, opts \\ []) when is_list(patterns) do
    %__MODULE__{patterns: patterns, body: body, binders: Keyword.get(opts, :binders, [])}
  end

  @doc "Materializes a clause body against a named equation context."
  @spec materialize(t(), Context.t()) :: Term.t()
  def materialize(%__MODULE__{body: body}, %Context{} = context) when is_function(body, 1),
    do: body.(context)

  def materialize(%__MODULE__{body: body}, %Context{}), do: body
end
