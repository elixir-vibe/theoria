defmodule Theoria.Typespec.Type do
  @moduledoc """
  Normalized, Elixir-facing representation of a typespec type fragment.

  This struct is deliberately shallow. It records typespec contracts as facts for
  tool integrations; it is not a trusted proof that an implementation satisfies
  the contract.
  """

  @type kind ::
          :term
          | :atom
          | :boolean
          | :integer
          | :non_neg_integer
          | :string
          | :list
          | :nonempty_list
          | :tuple
          | :tagged_tuple
          | :union
          | :struct
          | :map
          | :remote
          | :user
          | :literal
          | :var
          | :unsupported

  @type t :: %__MODULE__{
          kind: kind(),
          args: [t()],
          module: module() | nil,
          name: atom() | nil,
          value: term(),
          raw: term()
        }

  @enforce_keys [:kind]
  defstruct [:kind, :module, :name, :value, :raw, args: []]

  @doc "Returns true when the type could not be normalized into the supported subset."
  @spec unsupported?(t()) :: boolean()
  def unsupported?(%__MODULE__{kind: kind}), do: kind == :unsupported

  @doc "Returns a compact human-readable label for a normalized type."
  @spec format(t()) :: String.t()
  def format(%__MODULE__{kind: :term}), do: "term()"
  def format(%__MODULE__{kind: :atom}), do: "atom()"
  def format(%__MODULE__{kind: :boolean}), do: "boolean()"
  def format(%__MODULE__{kind: :integer}), do: "integer()"
  def format(%__MODULE__{kind: :non_neg_integer}), do: "non_neg_integer()"
  def format(%__MODULE__{kind: :string}), do: "String.t()"
  def format(%__MODULE__{kind: :map}), do: "map()"
  def format(%__MODULE__{kind: :list, args: [type]}), do: "[#{format(type)}]"

  def format(%__MODULE__{kind: :nonempty_list, args: [type]}),
    do: "nonempty_list(#{format(type)})"

  def format(%__MODULE__{kind: :tuple, args: args}),
    do: "{#{Enum.map_join(args, ", ", &format/1)}}"

  def format(%__MODULE__{kind: :tagged_tuple, value: tag, args: args}) do
    inner = [inspect(tag) | Enum.map(args, &format/1)]
    "{#{Enum.join(inner, ", ")}}"
  end

  def format(%__MODULE__{kind: :union, args: args}), do: Enum.map_join(args, " | ", &format/1)
  def format(%__MODULE__{kind: :struct, module: module}), do: "%#{inspect(module)}{}"

  def format(%__MODULE__{kind: :remote, module: module, name: name, args: args}) do
    rendered_args = Enum.map_join(args, ", ", &format/1)
    "#{inspect(module)}.#{name}(#{rendered_args})"
  end

  def format(%__MODULE__{kind: :user, name: name, args: args}) do
    rendered_args = Enum.map_join(args, ", ", &format/1)
    "#{name}(#{rendered_args})"
  end

  def format(%__MODULE__{kind: :literal, value: value}), do: inspect(value)
  def format(%__MODULE__{kind: :var, name: name}), do: Atom.to_string(name)
  def format(%__MODULE__{kind: :unsupported, raw: raw}), do: "unsupported(#{inspect(raw)})"
end
