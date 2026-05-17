defmodule Theoria.Lean.Encode do
  @moduledoc """
  Encodes Theoria core terms as Lean source for contributor oracle checks.

  This module is intentionally a direct renderer. It does not prove or simplify
  anything; Lean remains the external checker for generated files.
  """

  alias Theoria.Level
  alias Theoria.Term
  alias Theoria.Term.{App, BVar, Const, Eq, EqRec, Forall, Lam, Let, Refl, Sort}

  @lean_keywords MapSet.new(~w(
    Sort Prop Type fun forall let in match with if then else by exact theorem example def
    inductive namespace end universe variable rfl true false
  ))

  @constant_names %{
    Bool: "TBool",
    Nat: "TNat",
    zero: "TNat.zero",
    succ: "TNat.succ",
    nat_add: "TNat.add",
    true: "TBool.true_",
    false: "TBool.false_"
  }

  @doc "Encodes a Theoria term as a Lean expression."
  @spec term(Term.t()) :: String.t()
  def term(term), do: term(term, [])

  @doc "Encodes a Theoria term as a Lean expression with a de Bruijn context."
  @spec term(Term.t(), [String.t()]) :: String.t()
  def term(%Sort{level: level}, _context), do: sort(level)
  def term(%Const{name: name}, _context), do: constant(name)

  def term(%BVar{index: index}, context) do
    Enum.fetch!(context, index)
  end

  def term(%App{} = app, context) do
    {fun, args} = Term.Application.collect(app)

    args
    |> Enum.map_join(" ", &term(&1, context))
    |> prefix(term(fun, context))
    |> parens()
  end

  def term(%Lam{name: name, domain: domain, body: body}, context) do
    binder = fresh_name(name, context)
    "(fun (#{binder} : #{term(domain, context)}) => #{term(body, [binder | context])})"
  end

  def term(%Forall{name: :_, domain: domain, body: body}, context) do
    "(#{term(domain, context)} -> #{term(body, ["_" | context])})"
  end

  def term(%Forall{name: name, domain: domain, body: body}, context) do
    binder = fresh_name(name, context)
    "(forall (#{binder} : #{term(domain, context)}), #{term(body, [binder | context])})"
  end

  def term(%Let{name: name, type: type, value: value, body: body}, context) do
    binder = fresh_name(name, context)

    "(let #{binder} : #{term(type, context)} := #{term(value, context)}; #{term(body, [binder | context])})"
  end

  def term(%Eq{left: left, right: right}, context) do
    "(#{term(left, context)} = #{term(right, context)})"
  end

  def term(%Refl{}, _context), do: "rfl"

  def term(%EqRec{motive: motive, base: base, proof: proof}, context) do
    "(tEqRec #{term(motive, context)} #{term(base, context)} #{term(proof, context)})"
  end

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

  defp fresh_name(:_, context), do: fresh_name(:x, context)

  defp fresh_name(name, context) do
    base = identifier(name)

    if base in context or base == "_" do
      unused_name(base, context)
    else
      base
    end
  end

  defp unused_name(base, context) do
    Stream.iterate(0, &(&1 + 1))
    |> Stream.map(&"#{base}#{&1}")
    |> Enum.find(&(&1 not in context))
  end

  defp prefix("", head), do: head
  defp prefix(args, head), do: head <> " " <> args

  defp parens(source), do: "(" <> source <> ")"
end
