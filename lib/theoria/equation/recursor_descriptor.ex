defmodule Theoria.Equation.RecursorDescriptor do
  @moduledoc "Experimental/internal API for 0.1; subject to change before 0.2. Internal recursor-derived shape metadata for matcher descriptors."

  alias Theoria.Env
  alias Theoria.Env.Recursor
  alias Theoria.Env.RecursorRule
  alias Theoria.Equation.Schema

  @enforce_keys [:family, :recursor, :rules]
  defstruct [:family, :recursor, :rules]

  @type t :: %__MODULE__{
          family: atom(),
          recursor: Recursor.t(),
          rules: [RecursorRule.t()]
        }

  @doc "Builds recursor-derived matcher shape metadata for a schema."
  @spec from_schema(Env.t(), Schema.t()) :: {:ok, t()} | {:error, term()}
  def from_schema(%Env{} = env, %Schema{} = schema) do
    name = recursor_name(schema.family)

    with {:ok, recursor} <- fetch_recursor(env, name),
         :ok <- validate_recursor(schema, recursor) do
      {:ok, %__MODULE__{family: schema.family, recursor: recursor, rules: recursor.rules}}
    end
  end

  @doc "Returns the recursor name used by the current equation fragment for a family."
  @spec recursor_name(atom()) :: atom()
  def recursor_name(family), do: String.to_atom("#{family}_rec")

  defp fetch_recursor(env, name) do
    case Env.fetch_recursor(env, name) do
      {:ok, recursor} -> {:ok, recursor}
      :error -> {:error, {:missing_recursor, name}}
    end
  end

  defp validate_recursor(%Schema{} = schema, %Recursor{} = recursor) do
    cond do
      recursor.inductives != [inductive_name(schema.family)] ->
        {:error, {:recursor_family_mismatch, recursor.name, recursor.inductives, schema.family}}

      recursor.num_indices != 0 ->
        {:error, {:unsupported_indexed_recursor, recursor.name}}

      recursor.num_minors != length(recursor.rules) ->
        {:error, {:recursor_rule_count_mismatch, recursor.name}}

      true ->
        :ok
    end
  end

  defp inductive_name(:bool), do: :Bool
  defp inductive_name(:nat), do: :Nat
  defp inductive_name(:list), do: :List
  defp inductive_name(family), do: family
end
