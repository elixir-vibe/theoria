defmodule Theoria.Equation.Context do
  @moduledoc "Helpers for equation branch body contexts."

  alias Theoria.Term

  @type t :: %{optional(atom()) => Term.t()}

  @doc "Returns a named branch or outer value from an equation body context."
  @spec fetch!(t(), atom()) :: Term.t()
  def fetch!(context, name), do: Map.fetch!(context, name)
end
