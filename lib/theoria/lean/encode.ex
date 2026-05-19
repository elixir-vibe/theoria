defmodule Theoria.Lean.Encode do
  @moduledoc """
  Experimental before 1.0; the shape may change.

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
    False: "False",
    True: "True",
    true_intro: "True.intro",
    not: "Not",
    and: "And",
    Bool: "Bool",
    Nat: "Nat",
    zero: "Nat.zero",
    succ: "Nat.succ",
    nat_add: "tNatAdd",
    bool_not: "Bool.not",
    bool_and: "Bool.and",
    bool_or: "Bool.or",
    List: "List",
    list_nil: "(fun (a : Type) => (@List.nil a))",
    list_cons: "(fun (a : Type) => fun (x : a) => fun (xs : List a) => (@List.cons a x xs))",
    list_rec: "tListRec",
    list_ind: "tListInd",
    list_length: "(fun (a : Type) => fun (xs : List a) => List.length xs)",
    list_append:
      "(fun (a : Type) => fun (left : List a) => fun (right : List a) => List.append left right)",
    Vec: "TVec",
    vec_nil: "(fun (a : Type) => (@TVec.vec_nil a))",
    vec_cons:
      "(fun (a : Type) => fun (head : a) => fun (n : Nat) => fun (tail : TVec a n) => (@TVec.vec_cons a head n tail))",
    vec_validation_match: "tVecValidationMatch",
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
