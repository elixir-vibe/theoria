defmodule Theoria.Kernel.GeneratedTerm do
  @moduledoc "A generated closed term paired with its expected type for assurance tests."

  alias Theoria.Env
  alias Theoria.Term

  @enforce_keys [:env, :term, :type]
  defstruct [:name, :env, :term, :type]

  @type name :: atom() | {atom(), non_neg_integer()}
  @type t :: %__MODULE__{name: name() | nil, env: Env.t(), term: Term.t(), type: Term.t()}

  @spec new(Env.t(), Term.t(), Term.t(), name() | nil) :: t()
  def new(%Env{} = env, term, type, name \\ nil),
    do: %__MODULE__{name: name, env: env, term: term, type: type}
end
