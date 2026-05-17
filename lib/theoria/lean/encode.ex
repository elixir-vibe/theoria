defprotocol Theoria.Lean.Encodable do
  @moduledoc "Protocol for rendering Theoria structures as Lean oracle source."

  @fallback_to_any true

  @doc "Encodes a value as Lean source with a de Bruijn context."
  @spec encode(t(), [String.t()]) :: String.t()
  def encode(value, context)
end

defmodule Theoria.Lean.Encode do
  @moduledoc """
  Encodes Theoria core terms as Lean source for contributor oracle checks.

  The public API is intentionally small; concrete rendering is dispatched
  through `Theoria.Lean.Encodable` so each core term owns its Lean shape. The
  encoder does not prove or simplify anything; Lean remains the external checker
  for generated files.
  """

  alias Theoria.Lean.Encodable
  alias Theoria.Level
  alias Theoria.Term

  @lean_keywords MapSet.new(~w(
    Sort Prop Type fun forall let in match with if then else by exact theorem example def
    inductive namespace end universe variable rfl true false
  ))

  @constant_names %{
    Bool: "Bool",
    Nat: "Nat",
    zero: "Nat.zero",
    succ: "Nat.succ",
    nat_add: "tNatAdd",
    bool_not: "Bool.not",
    bool_and: "Bool.and",
    bool_or: "Bool.or",
    List: "List",
    list_nil: "List.nil",
    list_cons: "List.cons",
    list_length: "List.length",
    true: "Bool.true",
    false: "Bool.false"
  }

  @doc "Encodes a Theoria term as a Lean expression."
  @spec term(Term.t()) :: String.t()
  def term(term), do: term(term, [])

  @doc "Encodes a Theoria term as a Lean expression with a de Bruijn context."
  @spec term(Term.t(), [String.t()]) :: String.t()
  def term(term, context), do: Encodable.encode(term, context)

  @doc "Encodes a universe level as a Lean universe expression."
  @spec level(Level.t()) :: String.t()
  def level(%Level.Zero{}), do: "0"
  def level(%Level.Param{name: name}), do: identifier(name)
  def level(%Level.Succ{level: level}), do: "(#{level(level)} + 1)"
  def level(%Level.Max{left: left, right: right}), do: "(max #{level(left)} #{level(right)})"

  @doc "Encodes a sort level as `Prop`, `Type`, `Type n`, or `Sort u`."
  @spec sort(Level.t()) :: String.t()
  def sort(level) do
    level = Level.normalize(level)

    case Level.to_integer(level) do
      {:ok, 0} -> "Prop"
      {:ok, 1} -> "Type"
      {:ok, n} -> "Type #{n - 1}"
      :error -> "Sort #{level(level)}"
    end
  end

  @doc "Encodes an atom as a Lean identifier."
  @spec identifier(atom() | String.t()) :: String.t()
  def identifier(name) when is_atom(name) do
    name
    |> Atom.to_string()
    |> identifier()
  end

  def identifier("Elixir." <> rest), do: identifier(rest)

  def identifier(name) when is_binary(name) do
    name =
      name
      |> String.replace(~r/[^A-Za-z0-9_'.]/, "_")
      |> String.trim_leading("_")
      |> case do
        "" ->
          "x"

        <<first, _rest::binary>> = identifier when first in ?0..?9 ->
          "x_#{identifier}"

        identifier ->
          identifier
      end

    if MapSet.member?(@lean_keywords, name), do: "#{name}_", else: name
  end

  @doc "Encodes a Theoria constant name in the Lean oracle namespace."
  @spec constant(atom()) :: String.t()
  def constant(name), do: Map.get(@constant_names, name, identifier(name))

  @doc "Returns a binder name that does not collide with the current Lean context."
  @spec fresh_name(atom(), [String.t()]) :: String.t()
  def fresh_name(:_, context), do: fresh_name(:x, context)

  def fresh_name(name, context) do
    base = identifier(name)

    if base in context or base == "_" do
      unused_name(base, context)
    else
      base
    end
  end

  @doc "Applies a Lean function source to encoded argument sources."
  @spec apply_source(String.t(), [String.t()]) :: String.t()
  def apply_source(fun, []), do: fun
  def apply_source(fun, args), do: parens([fun, " ", Enum.intersperse(args, " ")])

  @doc "Wraps Lean source in parentheses."
  @spec parens(iodata()) :: String.t()
  def parens(source), do: IO.iodata_to_binary(["(", source, ")"])

  defp unused_name(base, context) do
    Stream.iterate(0, &(&1 + 1))
    |> Stream.map(&"#{base}#{&1}")
    |> Enum.find(&(&1 not in context))
  end
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Sort do
  alias Theoria.Lean.Encode

  def encode(%{level: level}, _context), do: Encode.sort(level)
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Const do
  alias Theoria.Lean.Encode

  def encode(%{name: name}, _context), do: Encode.constant(name)
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.BVar do
  def encode(%{index: index}, context), do: Enum.fetch!(context, index)
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.App do
  alias Theoria.Lean.Encode
  alias Theoria.Term
  alias Theoria.Term.Const

  def encode(app, context) do
    {fun, args} = Term.Application.collect(app)

    case {fun, args} do
      {%Const{name: :bool_rec}, [motive, on_true, on_false, major]} ->
        encode_bool_match(motive, on_true, on_false, major, context)

      {%Const{name: :bool_ind}, [motive, on_true, on_false, major]} ->
        encode_bool_match(motive, on_true, on_false, major, context)

      {%Const{name: :nat_rec}, [_motive, zero_case, succ_case, major]} ->
        Encode.apply_source("Nat.rec", encode_args([zero_case, succ_case, major], context))

      {%Const{name: :nat_ind}, [motive, zero_case, succ_case, major]} ->
        fun = "Nat.rec (motive := #{Encode.term(motive, context)})"
        Encode.apply_source(fun, encode_args([zero_case, succ_case, major], context))

      _other ->
        fun
        |> Encode.term(context)
        |> Encode.apply_source(encode_args(args, context))
    end
  end

  defp encode_bool_match(_motive, on_true, on_false, major, context) do
    "(match #{Encode.term(major, context)} with | Bool.true => #{Encode.term(on_true, context)} | Bool.false => #{Encode.term(on_false, context)})"
  end

  defp encode_args(args, context), do: Enum.map(args, &Encode.term(&1, context))
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Lam do
  alias Theoria.Lean.Encode
  alias Theoria.Term.Lam

  def encode(%Lam{name: name, domain: domain, body: body}, context) do
    binder = Encode.fresh_name(name, context)

    "(fun (#{binder} : #{Encode.term(domain, context)}) => #{Encode.term(body, [binder | context])})"
  end
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Forall do
  alias Theoria.Lean.Encode
  alias Theoria.Term.Forall

  def encode(%Forall{name: :_, domain: domain, body: body}, context) do
    "(#{Encode.term(domain, context)} -> #{Encode.term(body, ["_" | context])})"
  end

  def encode(%Forall{name: name, domain: domain, body: body}, context) do
    binder = Encode.fresh_name(name, context)

    "(forall (#{binder} : #{Encode.term(domain, context)}), #{Encode.term(body, [binder | context])})"
  end
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Let do
  alias Theoria.Lean.Encode

  def encode(%{name: name, type: type, value: value, body: body}, context) do
    binder = Encode.fresh_name(name, context)

    "(let #{binder} : #{Encode.term(type, context)} := #{Encode.term(value, context)}; #{Encode.term(body, [binder | context])})"
  end
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Eq do
  alias Theoria.Lean.Encode

  def encode(%{left: left, right: right}, context) do
    "(#{Encode.term(left, context)} = #{Encode.term(right, context)})"
  end
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.Refl do
  def encode(_refl, _context), do: "rfl"
end

defimpl Theoria.Lean.Encodable, for: Theoria.Term.EqRec do
  alias Theoria.Lean.Encode

  def encode(%{motive: motive, base: base, proof: proof}, context) do
    "(tEqRec #{Encode.term(motive, context)} #{Encode.term(base, context)} #{Encode.term(proof, context)})"
  end
end

defimpl Theoria.Lean.Encodable, for: Any do
  def encode(value, _context) do
    raise Protocol.UndefinedError,
      protocol: Theoria.Lean.Encodable,
      value: value,
      description: "cannot encode value as Lean source"
  end
end
