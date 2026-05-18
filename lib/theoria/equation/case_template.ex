defmodule Theoria.Equation.CaseTemplate do
  @moduledoc "Experimental/internal API for 0.1; subject to change before 0.2. Schematic equation case template used by schema generation."

  alias Theoria.Equation.Signature
  alias Theoria.Term

  @enforce_keys [:suffix, :left, :right]
  defstruct [:suffix, :left, :right, binders: [], equality_type: nil]

  @type t :: %__MODULE__{
          suffix: atom(),
          left: Term.t(),
          right: Term.t(),
          binders: [Signature.binder()],
          equality_type: Term.t() | nil
        }

  @doc "Builds one equation case template."
  @spec new(atom(), Term.t(), Term.t(), keyword()) :: t()
  def new(suffix, left, right, opts \\ []) when is_atom(suffix) do
    %__MODULE__{
      suffix: suffix,
      left: left,
      right: right,
      binders: Keyword.get(opts, :binders, []),
      equality_type: Keyword.get(opts, :equality_type)
    }
  end
end
