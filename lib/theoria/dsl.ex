defmodule Theoria.DSL do
  @moduledoc """
  Small Elixir DSL for constructing named Theoria syntax terms and theorem modules.

  The DSL is deliberately untrusted. It only builds `Theoria.Syntax` values;
  terms must still be elaborated and checked by `Theoria.Kernel`.

  ## Theorem modules

      defmodule MyProofs do
        use Theoria.DSL

        theorem :identity do
          type do
            forall :a, type(0) do
              forall :x, var(:a) do
                var(:a)
              end
            end
          end

          proof do
            lam :a, type(0) do
              lam :x, var(:a) do
                var(:x)
              end
            end
          end
        end
      end

      {:ok, theorem} = MyProofs.identity_theorem()

  The generated theorem functions are ordinary Elixir functions. Use
  `Theoria.Theorem.add_all_to_env/2` when later theorems in a module refer to
  earlier theorem constants.

  ## Quoted terms

  `term do ... end` accepts an Elixir-like term language where lowercase names
  become variables and function calls become constant applications:

      term do
        forall :p, prop() do
          p ~> p
        end
      end

      term do
        eq(bool(), bool_not(bool_true()), bool_false())
      end
  """

  alias Theoria.DSL.Quote
  alias Theoria.Elaborator
  alias Theoria.Syntax

  @doc "Imports the term-construction DSL."
  defmacro __using__(_opts) do
    quote do
      import Theoria.DSL
      import Theoria.DSL.Theorem
      Module.register_attribute(__MODULE__, :theoria_theorems, accumulate: true)
      @before_compile Theoria.DSL.Theorem
    end
  end

  @doc "The current proposition universe."
  def prop, do: Syntax.sort(0)

  @doc "The current core proposition universe, for APIs that need a checked core term."
  def core_prop, do: Theoria.Term.sort(0)

  @doc "A type universe. `type(0)` corresponds to `Type 0`, whose core sort is `Sort 1`."
  def type(level) when is_integer(level) and level >= 0, do: Syntax.sort(level + 1)

  @doc "A named bound variable."
  def var(name) when is_atom(name), do: Syntax.var(name)

  @doc "A named environment constant."
  def const(name, levels \\ []) when is_atom(name) and is_list(levels),
    do: Syntax.const(name, levels)

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

  @doc "Equality recursor."
  def eq_rec(type, motive, base, proof), do: Syntax.eq_rec(type, motive, base, proof)

  @doc "Elaborates a named syntax term to a core term."
  def elab(term), do: Elaborator.elaborate(term)

  @doc "Builds a Theoria syntax term from a small Elixir-like quoted expression."
  defmacro term(do: ast) do
    quoted = Quote.quote_term(ast)

    quote do
      unquote(quoted)
    end
  end

  @doc "Elaborates a named syntax term or raises `Theoria.Error`."
  def elab!(%Syntax.Sort{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Var{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Const{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.App{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Lam{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Forall{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Let{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Eq{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.Refl{} = term), do: Elaborator.elaborate!(term)
  def elab!(%Syntax.EqRec{} = term), do: Elaborator.elaborate!(term)

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
