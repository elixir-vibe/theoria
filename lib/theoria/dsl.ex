defmodule Theoria.DSL do
  @moduledoc """
  Small Elixir DSL for constructing named Theoria syntax terms.

  The DSL is deliberately untrusted. It only builds `Theoria.Syntax` values;
  terms must still be elaborated and checked by `Theoria.Kernel`.
  """

  alias Theoria.Elaborator
  alias Theoria.Syntax

  @doc "Imports the term-construction DSL."
  defmacro __using__(_opts) do
    quote do
      import Theoria.DSL
    end
  end

  @doc "The current proposition universe."
  def prop, do: Syntax.sort(0)

  @doc "The current core proposition universe, for APIs that need a checked core term."
  def core_prop, do: Theoria.Term.sort(0)

  @doc "A type universe. Currently aliases directly to `Sort n`."
  def type(level) when is_integer(level) and level >= 0, do: Syntax.sort(level)

  @doc "A named bound variable."
  def var(name) when is_atom(name), do: Syntax.var(name)

  @doc "A named environment constant."
  def const(name) when is_atom(name), do: Syntax.const(name)

  @doc "Function application."
  def app(fun, arg), do: Syntax.app(fun, arg)

  @doc "Applies `fun` to all `args` left-associatively."
  def call(fun, args) when is_list(args) do
    Enum.reduce(args, fun, &Syntax.app(&2, &1))
  end

  def call(fun, arg), do: call(fun, [arg])
  def call(fun, arg1, arg2), do: call(fun, [arg1, arg2])
  def call(fun, arg1, arg2, arg3), do: call(fun, [arg1, arg2, arg3])
  def call(fun, arg1, arg2, arg3, arg4), do: call(fun, [arg1, arg2, arg3, arg4])

  @doc "Non-dependent function type."
  def arrow(domain, codomain), do: Syntax.arrow(domain, codomain)

  @doc "Propositional equality."
  def eq(type, left, right), do: Syntax.eq(type, left, right)

  @doc "Reflexivity proof."
  def refl(value), do: Syntax.refl(value)

  @doc "Elaborates a named syntax term to a core term."
  def elab(term), do: Elaborator.elaborate(term)

  @doc "Elaborates a named syntax term or raises `Theoria.Error`."
  def elab!(%Syntax.Sort{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Var{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Const{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.App{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Lam{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Forall{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Eq{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Refl{} = term), do: Elaborator.elaborate!(term)

  @doc "Lambda abstraction with `do` block syntax."
  defmacro lam({name, _meta, context}, domain, do: body)
           when is_atom(name) and is_atom(context) do
    quote do
      Syntax.lam(unquote(name), unquote(domain), unquote(body))
    end
  end

  defmacro lam(name, domain, do: body) when is_atom(name) do
    quote do
      Syntax.lam(unquote(name), unquote(domain), unquote(body))
    end
  end

  @doc "Dependent function type with `do` block syntax."
  defmacro forall({name, _meta, context}, domain, do: body)
           when is_atom(name) and is_atom(context) do
    quote do
      Syntax.forall(unquote(name), unquote(domain), unquote(body))
    end
  end

  defmacro forall(name, domain, do: body) when is_atom(name) do
    quote do
      Syntax.forall(unquote(name), unquote(domain), unquote(body))
    end
  end
end
