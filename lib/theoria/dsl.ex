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
    quoted = quote_term(ast)

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

  defp quote_term({:__block__, _meta, [expr]}), do: quote_term(expr)

  defp quote_term({:__block__, _meta, exprs}) do
    raise ArgumentError,
          "term blocks must contain exactly one expression, got #{length(exprs)}"
  end

  defp quote_term({:^, _meta, [expr]}) do
    expr
  end

  defp quote_term({:var, _meta, [name]}) do
    quote do
      Theoria.Syntax.var(unquote(name_literal!(name)))
    end
  end

  defp quote_term({:const, _meta, [name]}) do
    quote do
      Theoria.Syntax.const(unquote(name_literal!(name)))
    end
  end

  defp quote_term({:const, _meta, [name, levels]}) do
    levels = quote_levels!(levels)

    quote do
      Theoria.Syntax.const(unquote(name_literal!(name)), unquote(levels))
    end
  end

  defp quote_term({:sort, _meta, [level]}) do
    level = quote_level(level)

    quote do
      Theoria.Syntax.sort(unquote(level))
    end
  end

  defp quote_term({:prop, _meta, []}) do
    quote do
      Theoria.Syntax.sort(0)
    end
  end

  defp quote_term({:bool_true, _meta, []}) do
    quote do
      Theoria.Syntax.const(true)
    end
  end

  defp quote_term({:bool_false, _meta, []}) do
    quote do
      Theoria.Syntax.const(false)
    end
  end

  defp quote_term({:bool, _meta, []}) do
    quote do
      Theoria.Syntax.const(:Bool)
    end
  end

  defp quote_term({:nat, _meta, []}) do
    quote do
      Theoria.Syntax.const(:Nat)
    end
  end

  defp quote_term({:true_prop, _meta, []}) do
    quote do
      Theoria.Syntax.const(:True)
    end
  end

  defp quote_term({:false_prop, _meta, []}) do
    quote do
      Theoria.Syntax.const(:False)
    end
  end

  defp quote_term({:zero, _meta, context}) when is_atom(context) do
    quote do
      Theoria.Syntax.const(:zero)
    end
  end

  defp quote_term({:succ, _meta, context}) when is_atom(context) do
    quote do
      Theoria.Syntax.const(:succ)
    end
  end

  defp quote_term({:list, _meta, [element_type]}) do
    quote_list_application(:List, 1, [element_type])
  end

  defp quote_term({:list, _meta, [element_type, level]}) do
    quote_list_application(:List, level, [element_type])
  end

  defp quote_term({:vec, _meta, [element_type, length]}) do
    quote_level_application(:Vec, [1], [element_type, length])
  end

  defp quote_term({:vec, _meta, [element_type, length, level]}) do
    quote_level_application(:Vec, [level], [element_type, length])
  end

  defp quote_term({name, _meta, context})
       when name in [:list_nil, :list_cons, :vec_nil, :vec_cons] and is_atom(context) do
    quote do
      Theoria.Syntax.const(unquote(name), [1])
    end
  end

  defp quote_term({name, _meta, args})
       when name in [:bool_rec, :bool_ind, :nat_rec, :nat_ind] and is_list(args) do
    quote_level_application(name, [1], args)
  end

  defp quote_term({name, _meta, args})
       when name in [:list_nil, :list_cons, :list_length, :list_append, :vec_nil, :vec_cons] and
              is_list(args) do
    quote_level_application(name, [1], args)
  end

  defp quote_term({name, _meta, args}) when name in [:list_rec, :list_ind] and is_list(args) do
    quote_level_application(name, [1, 1], args)
  end

  defp quote_term({:vec_ind, _meta, args}) when is_list(args) do
    quote_level_application(:vec_ind, [1], args)
  end

  defp quote_term({:type, _meta, [level]}) when is_integer(level) and level >= 0 do
    quote do
      Theoria.Syntax.sort(unquote(level + 1))
    end
  end

  defp quote_term({:refl, _meta, [value]}) do
    value = quote_term(value)

    quote do
      Theoria.Syntax.refl(unquote(value))
    end
  end

  defp quote_term({:eq_rec, _meta, [type, motive, base, proof]}) do
    type = quote_term(type)
    motive = quote_term(motive)
    base = quote_term(base)
    proof = quote_term(proof)

    quote do
      Theoria.Syntax.eq_rec(unquote(type), unquote(motive), unquote(base), unquote(proof))
    end
  end

  defp quote_term({operator, _meta, [domain, codomain]}) when operator in [:~>, :~>>] do
    domain = quote_term(domain)
    codomain = quote_term(codomain)

    quote do
      Theoria.Syntax.arrow(unquote(domain), unquote(codomain))
    end
  end

  defp quote_term({:arrow, _meta, [domain, codomain]}) do
    domain = quote_term(domain)
    codomain = quote_term(codomain)

    quote do
      Theoria.Syntax.arrow(unquote(domain), unquote(codomain))
    end
  end

  defp quote_term({:app, _meta, [fun, arg]}) do
    fun = quote_term(fun)
    arg = quote_term(arg)

    quote do
      Theoria.Syntax.app(unquote(fun), unquote(arg))
    end
  end

  defp quote_term({:forall, _meta, [name, domain, [do: body]]}) do
    domain = quote_term(domain)
    body = quote_term(body)

    quote do
      Theoria.Syntax.forall(unquote(quote_binder(name)), unquote(domain), unquote(body))
    end
  end

  defp quote_term({:forall, _meta, _args}) do
    raise ArgumentError,
          "expected forall binder syntax: forall :name, domain do ... end"
  end

  defp quote_term({:lam, _meta, [name, domain, [do: body]]}) do
    domain = quote_term(domain)
    body = quote_term(body)

    quote do
      Theoria.Syntax.lam(unquote(quote_binder(name)), unquote(domain), unquote(body))
    end
  end

  defp quote_term({:lam, _meta, _args}) do
    raise ArgumentError,
          "expected lambda binder syntax: lam :name, domain do ... end"
  end

  defp quote_term({:let, _meta, [name, type, value, [do: body]]}) do
    type = quote_term(type)
    value = quote_term(value)
    body = quote_term(body)

    quote do
      Theoria.Syntax.let(
        unquote(quote_binder(name)),
        unquote(type),
        unquote(value),
        unquote(body)
      )
    end
  end

  defp quote_term({:let, _meta, _args}) do
    raise ArgumentError,
          "expected let syntax: let :name, type, value do ... end"
  end

  defp quote_term({:eq, _meta, [type, left, right]}) do
    type = quote_term(type)
    left = quote_term(left)
    right = quote_term(right)

    quote do
      Theoria.Syntax.eq(unquote(type), unquote(left), unquote(right))
    end
  end

  defp quote_term({:neg, _meta, [proposition]}) do
    quote_application(:not, [proposition])
  end

  defp quote_term({:conj, _meta, [left, right]}) do
    quote_application(:and, [left, right])
  end

  defp quote_term({:__aliases__, _meta, [:Bool]}) do
    raise ArgumentError, "use bool() for the Theoria Bool type inside term blocks"
  end

  defp quote_term({:__aliases__, _meta, [:Nat]}) do
    raise ArgumentError, "use nat() for the Theoria Nat type inside term blocks"
  end

  defp quote_term({:__aliases__, _meta, [:List]}) do
    raise ArgumentError, "use list(element_type) for the Theoria List type inside term blocks"
  end

  defp quote_term({:__aliases__, _meta, parts}) do
    quote do
      Theoria.Syntax.const(unquote(Module.concat(parts)))
    end
  end

  defp quote_term({name, _meta, context}) when is_atom(name) and is_atom(context) do
    quote do
      Theoria.Syntax.var(unquote(name))
    end
  end

  defp quote_term({name, _meta, args}) when is_atom(name) and is_list(args) do
    quote_application(name, args)
  end

  defp quote_term(list) when is_list(list) do
    raise ArgumentError,
          "term blocks do not support Elixir lists; use list_nil/list_cons constants"
  end

  defp quote_term(tuple) when is_tuple(tuple) do
    raise ArgumentError,
          "term blocks do not support Elixir tuples; use explicit Theoria constructors"
  end

  defp quote_term(atom) when is_atom(atom) do
    quote do
      Theoria.Syntax.const(unquote(atom))
    end
  end

  defp quote_term(other) when is_binary(other) do
    raise ArgumentError, "term blocks do not support Elixir strings: #{inspect(other)}"
  end

  defp quote_term(other) when is_number(other) do
    raise ArgumentError, "term blocks do not support Elixir numbers: #{inspect(other)}"
  end

  defp quote_term(other) do
    raise ArgumentError, "unsupported Theoria term syntax: #{Macro.to_string(other)}"
  end

  defp quote_application(name, args) do
    args
    |> Enum.map(&quote_term/1)
    |> Enum.reduce(quote_const(name), fn arg, fun ->
      quote do
        Theoria.Syntax.app(unquote(fun), unquote(arg))
      end
    end)
  end

  defp quote_list_application(name, level, args) do
    quote_level_application(name, [level], args)
  end

  defp quote_level_application(name, levels, args) do
    args
    |> Enum.map(&quote_term/1)
    |> Enum.reduce(quote_const(name, levels), fn arg, fun ->
      quote do
        Theoria.Syntax.app(unquote(fun), unquote(arg))
      end
    end)
  end

  defp quote_const(name) do
    quote do
      Theoria.Syntax.const(unquote(name))
    end
  end

  defp quote_const(name, levels) do
    quote do
      Theoria.Syntax.const(unquote(name), unquote(quote_levels!(levels)))
    end
  end

  defp quote_levels!(levels) when is_list(levels), do: Enum.map(levels, &quote_level/1)

  defp quote_levels!(other) do
    raise ArgumentError, "expected a list of universe levels, got: #{Macro.to_string(other)}"
  end

  defp quote_level({:^, _meta, [expr]}), do: expr
  defp quote_level(level) when is_integer(level) and level >= 0, do: level
  defp quote_level(level) when is_atom(level), do: quote(do: Theoria.Level.param(unquote(level)))

  defp quote_level({name, _meta, context}) when is_atom(name) and is_atom(context) do
    quote do
      Theoria.Level.param(unquote(name))
    end
  end

  defp quote_level({:succ, _meta, [level]}) do
    level = quote_level(level)

    quote do
      Theoria.Level.succ(unquote(level))
    end
  end

  defp quote_level({:max, _meta, [left, right]}) do
    left = quote_level(left)
    right = quote_level(right)

    quote do
      Theoria.Level.max(unquote(left), unquote(right))
    end
  end

  defp quote_level(other) do
    raise ArgumentError, "unsupported universe level syntax: #{Macro.to_string(other)}"
  end

  defp quote_binder({:^, _meta, [expr]}), do: expr
  defp quote_binder(name), do: name_literal!(name)

  defp name_literal!(atom) when is_atom(atom), do: atom
  defp name_literal!({name, _meta, context}) when is_atom(name) and is_atom(context), do: name

  defp name_literal!(other) do
    raise ArgumentError, "expected an atom or variable name, got: #{Macro.to_string(other)}"
  end
end
