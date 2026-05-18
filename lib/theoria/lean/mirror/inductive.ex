defmodule Theoria.Lean.Mirror.Inductive do
  @moduledoc "Experimental/internal API for 0.1; subject to change before 0.2. Generates small Lean mirror declarations from Theoria inductive specs."

  alias Theoria.Inductive.Constructor
  alias Theoria.Inductive.Spec
  alias Theoria.Lean.Encode
  alias Theoria.Term.Sort

  @doc "Returns true when the oracle generator supports this inductive shape."
  @spec supports?(Spec.t()) :: boolean()
  def supports?(%Spec{
        name: :Vec,
        parameters: [_parameter],
        indices: [_index],
        constructors: [_, _]
      }),
      do: true

  def supports?(%Spec{}), do: false

  @doc "Returns a short reason when `source/1` cannot render a spec."
  @spec unsupported_reason(Spec.t()) :: String.t() | nil
  def unsupported_reason(%Spec{} = spec) do
    if supports?(spec) do
      nil
    else
      "only Vec-like single-parameter, single-index inductive specs are supported"
    end
  end

  @doc "Renders a Lean inductive declaration for the supported oracle fragment."
  @spec source(Spec.t()) :: {:ok, String.t()} | {:error, String.t()}
  def source(%Spec{} = spec) do
    if supports?(spec) do
      {:ok, source!(spec)}
    else
      {:error, unsupported_reason(spec)}
    end
  end

  @doc "Renders a Lean inductive declaration or raises if unsupported."
  @spec source!(Spec.t()) :: String.t()
  def source!(%Spec{name: :Vec} = spec) do
    params = render_params(spec)
    indices = render_indices(spec)
    constructors = Enum.map_join(spec.constructors, "\n", &render_constructor(&1, spec))

    """
    inductive #{lean_name(spec.name)} #{params} : #{indices}#{result_sort(spec)} where
    #{constructors}

    """
  end

  def source!(%Spec{name: name} = spec) do
    raise ArgumentError,
          "Lean oracle cannot generate inductive #{inspect(name)}: #{unsupported_reason(spec)}"
  end

  defp render_params(%Spec{parameters: parameters}) do
    parameters
    |> Enum.map(fn parameter ->
      ["(", Encode.identifier(parameter.name), " : ", parameter_type(parameter.type), ")"]
    end)
    |> Enum.intersperse(" ")
    |> IO.iodata_to_binary()
  end

  defp render_indices(%Spec{indices: indices}) do
    Enum.map_join(indices, " -> ", fn index -> Encode.term(index.type) end) <> " -> "
  end

  defp render_constructor(constructor, spec) do
    {:ok, result} = Constructor.result(constructor, spec)
    parameter_count = length(spec.parameters)
    fields = Enum.drop(result.binders, parameter_count)
    context = spec.parameters |> Enum.map(&Encode.identifier(&1.name)) |> Enum.reverse()
    {field_sources, context} = render_fields(fields, context, [])
    target = render_target(result.indices, context, spec)
    prefix = ["  | ", Encode.identifier(constructor.name), " : "]

    IO.iodata_to_binary([prefix, field_sources, target])
  end

  defp render_fields([], context, sources), do: {Enum.reverse(sources), context}

  defp render_fields([field | fields], context, sources) do
    name = Encode.fresh_name(field.name, context)
    source = ["(", name, " : ", Encode.term(field.domain, context), ") -> "]
    render_fields(fields, [name | context], [source | sources])
  end

  defp render_target(indices, context, spec) do
    args =
      Enum.map(spec.parameters, &Encode.identifier(&1.name)) ++
        Enum.map(indices, &Encode.term(&1, context))

    Encode.apply_source(lean_name(spec.name), args)
  end

  defp result_sort(%Spec{parameters: [%{type: %Sort{level: level}}]}) do
    lean_type_sort(level)
  end

  defp parameter_type(%Sort{level: level}) do
    lean_type_sort(level)
  end

  defp parameter_type(type), do: Encode.term(type)

  defp lean_type_sort(level) do
    case Theoria.Level.to_integer(Theoria.Level.normalize(level)) do
      {:ok, n} when n > 0 -> "Type #{n - 1}"
      _other -> "Type #{Encode.level(level)}"
    end
  end

  defp lean_name(name), do: "T" <> Encode.identifier(name)
end
