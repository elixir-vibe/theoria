defmodule Theoria.Equation.SchemaBuilder do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Internal builder for equation schemas and matcher metadata from signatures and case templates."

  alias Theoria.Equation.CaseTemplate
  alias Theoria.Equation.MatcherInfo
  alias Theoria.Equation.MatcherInfo.Discriminant
  alias Theoria.Equation.Schema
  alias Theoria.Equation.Signature

  @doc "Builds and validates a schema from a signature and schematic case templates."
  @spec build(Signature.t(), [CaseTemplate.t()]) :: {:ok, Schema.t()} | {:error, term()}
  def build(%Signature{} = signature, templates) when is_list(templates) do
    schema = %Schema{
      family: signature.family,
      recursive_argument: signature.rec_arg_pos,
      parameter_binders: signature.parameters,
      argument_binders: signature.arguments,
      equations: Enum.map(templates, &equation_for(&1, signature))
    }

    with :ok <- Schema.validate(schema) do
      {:ok, schema}
    end
  end

  @doc "Builds matcher metadata from a validated signature schema."
  @spec matcher(Signature.t(), Schema.t()) :: MatcherInfo.t()
  def matcher(%Signature{} = signature, %Schema{} = schema) do
    MatcherInfo.for_schema(signature.name, schema,
      discriminants: discriminants(signature),
      overlaps: overlaps(schema)
    )
  end

  @doc "Derives simple overlap metadata from duplicate equation alternatives."
  @spec overlaps(Schema.t()) :: %{optional(non_neg_integer()) => [non_neg_integer()]}
  def overlaps(%Schema{} = schema) do
    schema.equations
    |> Stream.with_index()
    |> Enum.reduce(%{}, fn {equation, index}, by_suffix ->
      Map.update(by_suffix, equation.suffix, [index], &[index | &1])
    end)
    |> Enum.flat_map(fn {_suffix, indexes} -> indexes |> Enum.reverse() |> overlap_entry() end)
    |> Map.new()
  end

  defp discriminants(%Signature{} = signature) do
    signature
    |> discriminant_positions()
    |> Enum.map(&discriminant(signature, &1))
  end

  defp discriminant_positions(%Signature{discriminant_positions: nil} = signature),
    do: [signature.rec_arg_pos]

  defp discriminant_positions(%Signature{discriminant_positions: positions}), do: positions

  defp discriminant(signature, position) do
    case Enum.at(signature.arguments, position) do
      {name, type} ->
        %Discriminant{name: name, position: position, type: type, family: signature.family}

      nil ->
        %Discriminant{position: position, family: signature.family}
    end
  end

  defp overlap_entry([_index]), do: []
  defp overlap_entry([first | rest]), do: [{first, rest}]

  defp equation_for(%CaseTemplate{} = template, signature) do
    Schema.equation(
      template.suffix,
      template.left,
      template.right,
      template.equality_type || signature.result_type,
      binders: template.binders
    )
  end
end
