defmodule Theoria.Equation.SchemaBuilder do
  @moduledoc "Builds equation schemas and matcher metadata from signatures and case templates."

  alias Theoria.Equation.CaseTemplate
  alias Theoria.Equation.MatcherInfo
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
    MatcherInfo.for_schema(signature.name, schema)
  end

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
