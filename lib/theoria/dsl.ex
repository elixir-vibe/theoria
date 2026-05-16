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
      Module.register_attribute(__MODULE__, :theoria_theorems, accumulate: true)
      @before_compile Theoria.DSL
    end
  end

  defmacro __before_compile__(env) do
    theorems =
      env.module
      |> Module.get_attribute(:theoria_theorems)
      |> Enum.reverse()

    quote do
      def __theoria_theorems__, do: unquote(theorems)
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

  @doc "Declares a checked theorem function trio from `type` and `proof` blocks."
  defmacro theorem(name, do: block) when is_atom(name) do
    {type_ast, proof_ast} = theorem_parts(block)
    type_fun = String.to_atom("#{name}_type")
    proof_fun = String.to_atom("#{name}_proof")
    theorem_fun = String.to_atom("#{name}_theorem")

    quote do
      @theoria_theorems unquote(name)

      @doc "Returns the unelaborated type syntax for theorem `#{unquote(name)}`."
      def unquote(type_fun)(), do: unquote(type_ast)

      @doc "Returns the unelaborated proof syntax for theorem `#{unquote(name)}`."
      def unquote(proof_fun)(), do: unquote(proof_ast)

      @doc "Elaborates and checks theorem `#{unquote(name)}` against the given environment."
      def unquote(theorem_fun)(env \\ Theoria.new_env()) do
        with {:ok, type} <- Theoria.Elaborator.elaborate(unquote(type_fun)()),
             {:ok, proof} <- Theoria.Elaborator.elaborate(unquote(proof_fun)()),
             :ok <- Theoria.Kernel.check(env, proof, type) do
          {:ok, %Theoria.Theorem{name: unquote(name), type: type, proof: proof}}
        end
      end
    end
  end

  defp theorem_parts({:__block__, _meta, expressions}) do
    Enum.reduce(expressions, {nil, nil}, &theorem_part/2)
    |> validate_theorem_parts!()
  end

  defp theorem_parts(expression) do
    theorem_part(expression, {nil, nil})
    |> validate_theorem_parts!()
  end

  defp theorem_part({:type, _meta, [[do: body]]}, {_type, proof}), do: {body, proof}
  defp theorem_part({:proof, _meta, [[do: body]]}, {type, _proof}), do: {type, body}

  defp theorem_part(other, _acc) do
    raise ArgumentError,
          "expected theorem blocks named type/proof, got: #{Macro.to_string(other)}"
  end

  defp validate_theorem_parts!({nil, _proof}),
    do: raise(ArgumentError, "theorem is missing a type block")

  defp validate_theorem_parts!({_type, nil}),
    do: raise(ArgumentError, "theorem is missing a proof block")

  defp validate_theorem_parts!({type, proof}), do: {type, proof}

  defp quote_term({:__block__, _meta, [expr]}), do: quote_term(expr)

  defp quote_term({:__block__, _meta, exprs}) do
    raise ArgumentError,
          "term blocks must contain exactly one expression, got #{length(exprs)}"
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
    quote_application(:List, [element_type])
  end

  defp quote_term({name, _meta, context})
       when name in [:list_nil, :list_cons] and is_atom(context) do
    quote do
      Theoria.Syntax.const(unquote(name))
    end
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
      Theoria.Syntax.forall(unquote(name_literal!(name)), unquote(domain), unquote(body))
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
      Theoria.Syntax.lam(unquote(name_literal!(name)), unquote(domain), unquote(body))
    end
  end

  defp quote_term({:lam, _meta, _args}) do
    raise ArgumentError,
          "expected lambda binder syntax: lam :name, domain do ... end"
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

  defp quote_const(name) do
    quote do
      Theoria.Syntax.const(unquote(name))
    end
  end

  defp name_literal!(atom) when is_atom(atom), do: atom
  defp name_literal!({name, _meta, context}) when is_atom(name) and is_atom(context), do: name

  defp name_literal!(other) do
    raise ArgumentError, "expected an atom or variable name, got: #{Macro.to_string(other)}"
  end
end
