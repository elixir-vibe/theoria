defmodule Theoria.Rewrite.Rule do
  @moduledoc "A theorem-like rewrite rule over a core equality term."

  alias Theoria.Term

  @enforce_keys [:name, :equality]
  defstruct [:name, :equality, direction: :forward]

  @type t :: %__MODULE__{name: atom(), equality: Term.Eq.t(), direction: :forward | :backward}

  @doc "Builds a rewrite rule."
  @spec new(atom(), Term.Eq.t(), keyword()) :: t()
  def new(name, %Term.Eq{} = equality, opts \\ []) when is_atom(name) do
    %__MODULE__{
      name: name,
      equality: equality,
      direction: Keyword.get(opts, :direction, :forward)
    }
  end
end
