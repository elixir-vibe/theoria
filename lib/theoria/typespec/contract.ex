defmodule Theoria.Typespec.Contract do
  @moduledoc """
  Normalized contract for one Elixir `@spec` clause.

  Contracts are facts extracted from BEAM typespec metadata. They are useful as
  preconditions and compatibility data for obligations, but they are not proofs
  about implementation behavior.
  """

  alias Theoria.Typespec.Type

  @type t :: %__MODULE__{
          module: module(),
          function: atom(),
          arity: non_neg_integer(),
          args: [Type.t()],
          result: Type.t(),
          raw: term(),
          source: :spec
        }

  @enforce_keys [:module, :function, :arity, :args, :result, :raw]
  defstruct [:module, :function, :arity, :args, :result, :raw, source: :spec]

  @doc "Returns the `{module, function, arity}` tuple for the contract."
  @spec mfa(t()) :: {module(), atom(), non_neg_integer()}
  def mfa(%__MODULE__{module: module, function: function, arity: arity}),
    do: {module, function, arity}

  @doc "Returns true when any argument or result type is outside the normalized subset."
  @spec unsupported?(t()) :: boolean()
  def unsupported?(%__MODULE__{args: args, result: result}) do
    Enum.any?([result | args], &contains_unsupported?/1)
  end

  @doc "Formats a contract for diagnostics."
  @spec format(t()) :: String.t()
  def format(%__MODULE__{} = contract) do
    args = Enum.map_join(contract.args, ", ", &Type.format/1)
    result = Type.format(contract.result)
    "#{inspect(contract.module)}.#{contract.function}(#{args}) :: #{result}"
  end

  defp contains_unsupported?(%Type{kind: :unsupported}), do: true
  defp contains_unsupported?(%Type{args: args}), do: Enum.any?(args, &contains_unsupported?/1)
end
