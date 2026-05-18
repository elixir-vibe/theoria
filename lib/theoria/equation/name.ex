defmodule Theoria.Equation.Name do
  @moduledoc "Structured identity for generated equation artifacts."

  @enforce_keys [:owner, :kind, :target]
  defstruct [:owner, :kind, :target, namespace: nil]

  @type kind :: :equation | :unfold | :matcher_equation | :indexed_matcher_equation
  @type t :: %__MODULE__{owner: atom(), kind: kind(), target: atom(), namespace: atom() | nil}
  @type selector :: t() | keyword()

  @doc "Builds a definition equation name."
  @spec equation(atom(), atom()) :: t()
  def equation(owner, target) when is_atom(owner) and is_atom(target),
    do: %__MODULE__{owner: owner, kind: :equation, target: target}

  @doc "Builds a definition unfold equation name."
  @spec unfold(atom()) :: t()
  def unfold(owner) when is_atom(owner),
    do: %__MODULE__{owner: owner, kind: :unfold, target: :def}

  @doc "Builds a matcher equation name."
  @spec matcher_equation(atom(), atom()) :: t()
  def matcher_equation(owner, target) when is_atom(owner) and is_atom(target),
    do: %__MODULE__{owner: owner, kind: :matcher_equation, target: target}

  @doc "Builds an indexed matcher equation name."
  @spec indexed_matcher_equation(atom(), atom()) :: t()
  def indexed_matcher_equation(owner, target) when is_atom(owner) and is_atom(target),
    do: %__MODULE__{owner: owner, kind: :indexed_matcher_equation, target: target}

  @doc "Casts API selectors to structured names."
  @spec cast(selector(), atom() | nil, kind() | nil) :: {:ok, t()} | {:error, term()}
  def cast(selector, owner \\ nil, kind \\ nil)
  def cast(%__MODULE__{} = name, _owner, _kind), do: {:ok, name}

  def cast(selector, owner, kind) when is_list(selector) and is_atom(owner) and is_atom(kind) do
    cond do
      target = Keyword.get(selector, :equation) ->
        {:ok, %__MODULE__{owner: owner, kind: kind, target: target}}

      target = Keyword.get(selector, :constructor) ->
        {:ok, %__MODULE__{owner: owner, kind: kind, target: target}}

      target = Keyword.get(selector, :target) ->
        {:ok, %__MODULE__{owner: owner, kind: kind, target: target}}

      true ->
        {:error, {:invalid_equation_selector, selector}}
    end
  end

  @doc "Returns the internal kernel declaration atom for a structured equation name."
  @spec to_declaration(t()) :: atom()
  def to_declaration(%__MODULE__{} = name) do
    ["theoria", kind_segment(name.kind), Atom.to_string(name.owner), target_segment(name.target)]
    |> Enum.join("__")
    |> String.to_atom()
  end

  @doc "Formats a kernel declaration atom when it is an equation declaration."
  @spec format_declaration(atom()) :: String.t()
  def format_declaration(name) when is_atom(name) do
    case Atom.to_string(name) do
      "theoria__eq__" <> rest -> format_declaration_parts(rest)
      "theoria__unfold__" <> rest -> format_declaration_parts(rest)
      "theoria__matcher_eq__" <> rest -> format_declaration_parts(rest)
      "theoria__indexed_matcher_eq__" <> rest -> format_declaration_parts(rest)
      other -> other
    end
  end

  @doc "Formats a structured equation name for humans."
  @spec format(t()) :: String.t()
  def format(%__MODULE__{owner: owner, kind: :equation, target: target}),
    do: "#{owner}.eq_#{target_segment(target)}"

  def format(%__MODULE__{owner: owner, kind: :unfold}),
    do: "#{owner}.eq_def"

  def format(%__MODULE__{owner: owner, kind: :matcher_equation, target: target}),
    do: "#{owner}.eq_#{target_segment(target)}"

  def format(%__MODULE__{owner: owner, kind: :indexed_matcher_equation, target: target}),
    do: "#{owner}.eq_#{target_segment(target)}"

  defp format_declaration_parts(rest) do
    case String.split(rest, "__", parts: 2) do
      [owner, "def"] -> "#{owner}.eq_def"
      [owner, target] -> "#{owner}.eq_#{target}"
      [name] -> name
    end
  end

  defp target_segment(nil), do: "nil"
  defp target_segment(target), do: Atom.to_string(target)

  defp kind_segment(:equation), do: "eq"
  defp kind_segment(:unfold), do: "unfold"
  defp kind_segment(:matcher_equation), do: "matcher_eq"
  defp kind_segment(:indexed_matcher_equation), do: "indexed_matcher_eq"
end

defimpl Inspect, for: Theoria.Equation.Name do
  import Inspect.Algebra

  def inspect(name, _opts),
    do: concat(["#Theoria.EquationName<", Theoria.Equation.Name.format(name), ">"])
end
