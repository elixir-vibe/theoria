defmodule Theoria.Lean.Module do
  @moduledoc "Builds Lean oracle source files from encoded checks."

  alias Theoria.Lean.Encode
  alias Theoria.Lean.MirrorPrelude
  alias Theoria.Term

  defstruct checks: []

  @type check ::
          {:proof, String.t(), Term.t(), Term.t()} | {:defeq, String.t(), Term.t(), Term.t()}
  @type t :: %__MODULE__{checks: [check()]}

  @doc "Creates an empty Lean oracle module."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc "Adds a proof check, rendered as `#check (proof : type)`."
  @spec add_proof_check(t(), String.t(), Term.t(), Term.t()) :: t()
  def add_proof_check(%__MODULE__{checks: checks} = module, name, proof, type) do
    %__MODULE__{module | checks: checks ++ [{:proof, name, proof, type}]}
  end

  @doc "Adds a definitional-equality check, rendered as `example : left = right := rfl`."
  @spec add_defeq_check(t(), String.t(), Term.t(), Term.t()) :: t()
  def add_defeq_check(%__MODULE__{checks: checks} = module, name, left, right) do
    %__MODULE__{module | checks: checks ++ [{:defeq, name, left, right}]}
  end

  @doc "Renders the complete Lean source file."
  @spec render(t()) :: String.t()
  def render(%__MODULE__{checks: checks}) do
    body = Enum.map_join(checks, "\n", &render_check/1)
    MirrorPrelude.source() <> body <> "\nend TheoriaOracle\n"
  end

  defp render_check({:proof, name, proof, type}) do
    """
    -- proof #{name}
    #check (#{Encode.term(proof)} : #{Encode.term(type)})
    """
  end

  defp render_check({:defeq, name, left, right}) do
    """
    -- defeq #{name}
    example : #{Encode.term(left)} = #{Encode.term(right)} := rfl
    """
  end
end
