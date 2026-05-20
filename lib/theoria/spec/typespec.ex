defmodule Theoria.Spec.Typespec do
  @moduledoc """
  Shallow compatibility checks for normalized Elixir typespec facts.

  This module is a small spec vocabulary for API-shape claims. It intentionally
  checks conservative structural compatibility over `Theoria.Typespec.Type` and
  `Theoria.Typespec.Contract` data; it does not prove that implementations obey
  their specs.
  """

  alias Theoria.Typespec.Contract
  alias Theoria.Typespec.Type

  defmodule Compatibility do
    @moduledoc "Structured result for a typespec compatibility claim."

    @type t :: %__MODULE__{
            old: term(),
            new: term(),
            compatible?: boolean(),
            reason: atom() | nil
          }

    @enforce_keys [:old, :new, :compatible?]
    defstruct [:old, :new, :compatible?, :reason]

    @doc "Returns true when the compatibility claim succeeded."
    @spec compatible?(t()) :: boolean()
    def compatible?(%__MODULE__{compatible?: compatible?}), do: compatible?

    @doc "Returns the failure reason, if any."
    @spec reason(t()) :: atom() | nil
    def reason(%__MODULE__{reason: reason}), do: reason
  end

  @doc "Returns true when `new` is structurally compatible with `old`."
  @spec compatible?(Type.t(), Type.t()) :: boolean()
  def compatible?(%Type{} = old, %Type{} = new), do: compatibility(old, new).compatible?

  @doc "Builds a structured compatibility claim for two normalized types."
  @spec compatibility(Type.t(), Type.t()) :: Compatibility.t()
  def compatibility(%Type{} = old, %Type{} = new) do
    reason = type_reason(old, new)
    %Compatibility{old: old, new: new, compatible?: is_nil(reason), reason: reason}
  end

  @doc "Returns true when a new contract preserves an old public API shape."
  @spec contract_compatible?(Contract.t(), Contract.t()) :: boolean()
  def contract_compatible?(%Contract{} = old, %Contract{} = new) do
    contract_compatibility(old, new).compatible?
  end

  @doc "Builds a structured compatibility claim for two contracts."
  @spec contract_compatibility(Contract.t(), Contract.t()) :: Compatibility.t()
  def contract_compatibility(%Contract{} = old, %Contract{} = new) do
    reason = contract_reason(old, new)
    %Compatibility{old: old, new: new, compatible?: is_nil(reason), reason: reason}
  end

  defp contract_reason(old, new) do
    cond do
      Contract.mfa(old) != Contract.mfa(new) ->
        :different_mfa

      length(old.args) != length(new.args) ->
        :different_arity

      not same_argument_shapes?(old.args, new.args) ->
        :argument_shape_changed

      reason = type_reason(old.result, new.result) ->
        {:result_incompatible, reason}

      true ->
        nil
    end
  end

  defp same_argument_shapes?(old_args, new_args) do
    Enum.zip(old_args, new_args)
    |> Enum.all?(fn {old, new} ->
      type_reason(old, new) == nil and type_reason(new, old) == nil
    end)
  end

  defp type_reason(%Type{kind: :term}, %Type{}), do: nil
  defp type_reason(%Type{kind: :unsupported}, _new), do: :unsupported_old_type
  defp type_reason(_old, %Type{kind: :unsupported}), do: :unsupported_new_type

  defp type_reason(%Type{kind: kind}, %Type{kind: kind})
       when kind in [:atom, :boolean, :integer, :non_neg_integer, :string, :map], do: nil

  defp type_reason(%Type{kind: :integer}, %Type{kind: :non_neg_integer}), do: nil

  defp type_reason(%Type{kind: :atom}, %Type{kind: :literal, value: value}) when is_atom(value),
    do: nil

  defp type_reason(%Type{kind: :integer}, %Type{kind: :literal, value: value})
       when is_integer(value), do: nil

  defp type_reason(%Type{kind: :literal, value: value}, %Type{kind: :literal, value: value}),
    do: nil

  defp type_reason(%Type{kind: :list, args: [old]}, %Type{kind: :list, args: [new]}),
    do: type_reason(old, new)

  defp type_reason(%Type{kind: :nonempty_list, args: [old]}, %Type{
         kind: :nonempty_list,
         args: [new]
       }),
       do: type_reason(old, new)

  defp type_reason(%Type{kind: :list, args: [old]}, %Type{kind: :nonempty_list, args: [new]}),
    do: type_reason(old, new)

  defp type_reason(%Type{kind: :tuple, args: old_args}, %Type{kind: :tuple, args: new_args}),
    do: args_reason(old_args, new_args)

  defp type_reason(
         %Type{kind: :tagged_tuple, value: tag, args: old_args},
         %Type{kind: :tagged_tuple, value: tag, args: new_args}
       ),
       do: args_reason(old_args, new_args)

  defp type_reason(%Type{kind: :union, args: old_args}, %Type{kind: :union, args: new_args}) do
    if Enum.all?(new_args, &covered_by_union?(&1, old_args)),
      do: nil,
      else: :union_variant_not_covered
  end

  defp type_reason(%Type{kind: :union, args: old_args}, %Type{} = new),
    do: if(covered_by_union?(new, old_args), do: nil, else: :union_variant_not_covered)

  defp type_reason(%Type{kind: :struct, module: module}, %Type{kind: :struct, module: module}),
    do: nil

  defp type_reason(
         %Type{kind: :remote, module: module, name: name, args: old_args},
         %Type{kind: :remote, module: module, name: name, args: new_args}
       ),
       do: args_reason(old_args, new_args)

  defp type_reason(%Type{kind: :user, name: name, args: old_args}, %Type{
         kind: :user,
         name: name,
         args: new_args
       }),
       do: args_reason(old_args, new_args)

  defp type_reason(_old, _new), do: :different_type_shape

  defp args_reason(old_args, new_args) when length(old_args) == length(new_args) do
    old_args
    |> Enum.zip(new_args)
    |> Enum.find_value(fn {old, new} -> type_reason(old, new) end)
  end

  defp args_reason(_old_args, _new_args), do: :different_type_arity

  defp covered_by_union?(type, union_args),
    do: Enum.any?(union_args, &(type_reason(&1, type) == nil))
end
