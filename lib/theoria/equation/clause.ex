defmodule Theoria.Equation.Clause do
  @moduledoc "A constructor equation clause."

  alias Theoria.Equation.Pattern
  alias Theoria.Term

  @enforce_keys [:patterns, :body]
  defstruct [:patterns, :body, binders: []]

  @type body :: Term.t() | (Theoria.Equation.Context.t() -> Term.t())
  @type t :: %__MODULE__{patterns: [Pattern.t()], body: body(), binders: [atom()]}

  @doc "Builds an equation clause."
  @spec new([Pattern.t()], body(), keyword()) :: t()
  def new(patterns, body, opts \\ []) when is_list(patterns) do
    %__MODULE__{patterns: patterns, body: body, binders: Keyword.get(opts, :binders, [])}
  end
end
