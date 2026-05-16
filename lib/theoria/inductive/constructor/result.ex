defmodule Theoria.Inductive.Constructor.Result do
  @moduledoc "Decomposed constructor target and binders."

  alias Theoria.Term
  alias Theoria.Term.Const

  @enforce_keys [:binders, :head, :arguments, :parameters, :indices]
  defstruct [:binders, :head, arguments: [], parameters: [], indices: []]

  @type binder :: %{name: atom(), domain: Term.t(), depth: non_neg_integer()}

  @type t :: %__MODULE__{
          binders: [binder()],
          head: Const.t(),
          arguments: [Term.t()],
          parameters: [Term.t()],
          indices: [Term.t()]
        }
end
