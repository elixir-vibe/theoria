defmodule Theoria.Typespec do
  @moduledoc """
  Normalizes Elixir `@spec` metadata into Theoria-friendly contract facts.

  Typespec facts are Elixir-native inputs for future obligations and tool
  integrations. They are not trusted proofs. Unsupported fragments are preserved
  as `Theoria.Typespec.Type` values with `kind: :unsupported` so callers can
  explain why a claim could not be certified.
  """

  alias Theoria.Typespec.Contract
  alias Theoria.Typespec.Report
  alias Theoria.Typespec.Type

  @doc "Fetches and normalizes all specs for a loaded module."
  @spec fetch(module()) :: {:ok, [Contract.t()]} | {:error, term()}
  def fetch(module) when is_atom(module) do
    case Code.Typespec.fetch_specs(module) do
      {:ok, specs} -> {:ok, normalize_specs(module, specs)}
      :error -> {:error, :no_typespecs}
    end
  end

  @doc "Fetches a structured report for a loaded module's specs."
  @spec report(module()) :: {:ok, Report.t()} | {:error, term()}
  def report(module) when is_atom(module) do
    case fetch(module) do
      {:ok, contracts} -> {:ok, Report.new(module, contracts)}
      {:error, _reason} = error -> error
    end
  end

  @doc "Fetches normalized contracts for one `{module, function, arity}`."
  @spec from_mfa({module(), atom(), non_neg_integer()}) ::
          {:ok, [Contract.t()]} | {:error, term()}
  def from_mfa({module, function, arity}) when is_atom(module) and is_atom(function) do
    with {:ok, contracts} <- fetch(module) do
      selected = Enum.filter(contracts, &(&1.function == function and &1.arity == arity))

      case selected do
        [] -> {:error, {:unknown_typespec, {module, function, arity}}}
        _contracts -> {:ok, selected}
      end
    end
  end

  defp normalize_specs(module, specs) do
    specs
    |> Enum.flat_map(fn {{function, arity}, clauses} ->
      Enum.map(clauses, &normalize_contract(module, function, arity, &1))
    end)
    |> Enum.sort_by(&{&1.function, &1.arity, Contract.format(&1)})
  end

  defp normalize_contract(module, function, arity, {:type, _meta, :fun, [product, result]} = raw) do
    %Contract{
      module: module,
      function: function,
      arity: arity,
      args: normalize_product(product),
      result: normalize_type(result),
      raw: raw
    }
  end

  defp normalize_contract(module, function, arity, raw) do
    %Contract{
      module: module,
      function: function,
      arity: arity,
      args: [],
      result: unsupported(raw),
      raw: raw
    }
  end

  defp normalize_product({:type, _meta, :product, args}), do: Enum.map(args, &normalize_type/1)
  defp normalize_product(other), do: [unsupported(other)]

  defp normalize_type({:type, _meta, :term, []}), do: %Type{kind: :term}
  defp normalize_type({:type, _meta, :any, []}), do: %Type{kind: :term}
  defp normalize_type({:type, _meta, :atom, []}), do: %Type{kind: :atom}
  defp normalize_type({:type, _meta, :boolean, []}), do: %Type{kind: :boolean}
  defp normalize_type({:type, _meta, :integer, []}), do: %Type{kind: :integer}
  defp normalize_type({:type, _meta, :non_neg_integer, []}), do: %Type{kind: :non_neg_integer}
  defp normalize_type({:type, _meta, :binary, []}), do: %Type{kind: :string}
  defp normalize_type({:type, _meta, :map, _fields}), do: %Type{kind: :map}

  defp normalize_type({:type, _meta, :list, [type]}),
    do: %Type{kind: :list, args: [normalize_type(type)]}

  defp normalize_type({:type, _meta, :nonempty_list, [type]}),
    do: %Type{kind: :nonempty_list, args: [normalize_type(type)]}

  defp normalize_type({:type, _meta, :tuple, :any}), do: %Type{kind: :tuple}

  defp normalize_type({:type, _meta, :tuple, [{:atom, _tag_meta, tag} | rest]}) do
    %Type{kind: :tagged_tuple, value: tag, args: Enum.map(rest, &normalize_type/1)}
  end

  defp normalize_type({:type, _meta, :tuple, args}) when is_list(args),
    do: %Type{kind: :tuple, args: Enum.map(args, &normalize_type/1)}

  defp normalize_type({:type, _meta, :union, args}),
    do: %Type{kind: :union, args: Enum.map(args, &normalize_type/1)}

  defp normalize_type({:remote_type, _meta, [{:atom, _, String}, {:atom, _, :t}, []]}),
    do: %Type{kind: :string}

  defp normalize_type({:remote_type, _meta, [{:atom, _, module}, {:atom, _, :t}, []]}) do
    if struct_module?(module),
      do: %Type{kind: :struct, module: module},
      else: %Type{kind: :remote, module: module, name: :t}
  end

  defp normalize_type({:remote_type, _meta, [{:atom, _, module}, {:atom, _, name}, args]}),
    do: %Type{kind: :remote, module: module, name: name, args: Enum.map(args, &normalize_type/1)}

  defp normalize_type({:user_type, _meta, name, args}),
    do: %Type{kind: :user, name: name, args: Enum.map(args, &normalize_type/1)}

  defp normalize_type({:var, _meta, name}), do: %Type{kind: :var, name: name}
  defp normalize_type({:atom, _meta, value}), do: %Type{kind: :literal, value: value}
  defp normalize_type({:integer, _meta, value}), do: %Type{kind: :literal, value: value}
  defp normalize_type(other), do: unsupported(other)

  defp unsupported(raw), do: %Type{kind: :unsupported, raw: raw}

  defp struct_module?(module) do
    Code.ensure_loaded?(module) and function_exported?(module, :__struct__, 0)
  end
end
