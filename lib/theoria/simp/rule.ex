defmodule Theoria.Simp.Rule do
  @moduledoc "Experimental before 1.0; the shape may change. Simplifier rule metadata layered over untrusted rewrite rules."

  alias Theoria.Rewrite

  @enforce_keys [:rewrite]
  defstruct [:rewrite, priority: 1000, source: :equation]

  @type t :: %__MODULE__{
          rewrite: Rewrite.Rule.t(),
          priority: integer(),
          source: atom()
        }

  @doc "Builds simplifier rule metadata."
  @spec new(Rewrite.Rule.t(), keyword()) :: t()
  def new(%Rewrite.Rule{} = rewrite, opts \\ []) do
    %__MODULE__{
      rewrite: rewrite,
      priority: Keyword.get(opts, :priority, 1000),
      source: Keyword.get(opts, :source, :equation)
    }
  end
end
