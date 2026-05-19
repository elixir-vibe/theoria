defmodule Theoria.Kernel.GeneratedTerm do
  @moduledoc "A generated closed term paired with its expected type for assurance tests."

  alias Theoria.Env
  alias Theoria.Term

  @enforce_keys [:env, :term, :type]
  defstruct [:env, :term, :type]

  @type t :: %__MODULE__{env: Env.t(), term: Term.t(), type: Term.t()}

  @spec new(Env.t(), Term.t(), Term.t()) :: t()
  def new(%Env{} = env, term, type), do: %__MODULE__{env: env, term: term, type: type}
end
