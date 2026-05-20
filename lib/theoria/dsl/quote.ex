defmodule Theoria.DSL.Quote do
  @moduledoc "Term quotation implementation for `Theoria.DSL`."

  alias Theoria.DSL.Quote.Prelude

  @doc "Builds quoted Elixir code that constructs a Theoria syntax term."
  def quote_term(ast) do
    do_quote_term(ast)
  end

  defp do_quote_term({:__block__, _meta, [expr]}), do: do_quote_term(expr)

  defp do_quote_term({:__block__, _meta, exprs}) do
    raise ArgumentError,
          "term blocks must contain exactly one expression, got #{length(exprs)}"
  end

  defp do_quote_term({:^, _meta, [expr]}) do
    expr
  end

  defp do_quote_term({:var, _meta, [name]}) do
    quote do
      Theoria.Syntax.var(unquote(name_literal!(name)))
    end
  end

  defp do_quote_term({:const, _meta, [name]}) do
    quote do
      Theoria.Syntax.const(unquote(name_literal!(name)))
    end
  end

  defp do_quote_term({:const, _meta, [name, levels]}) do
    levels = quote_levels!(levels)

    quote do
      Theoria.Syntax.const(unquote(name_literal!(name)), unquote(levels))
    end
  end

  defp do_quote_term({:sort, _meta, [level]}) do
    level = quote_level(level)

    quote do
      Theoria.Syntax.sort(unquote(level))
    end
  end

  defp do_quote_term({:prop, _meta, []}) do
    quote do
      Theoria.Syntax.sort(0)
    end
  end

  defp do_quote_term(ast) do
    case Prelude.quote_term(ast, &do_quote_term/1) do
      {:ok, quoted} -> quoted
      :error -> do_core_quote_term(ast)
    end
  end

  defp do_core_quote_term({:type, _meta, [level]}) when is_integer(level) and level >= 0 do
    quote do
      Theoria.Syntax.sort(unquote(level + 1))
    end
  end

  defp do_core_quote_term({:type, _meta, [level]}) do
    raise ArgumentError,
          "expected type universe level to be a non-negative integer, got: #{Macro.to_string(level)}"
  end

  defp do_core_quote_term({:type, _meta, _args}) do
    raise ArgumentError, "expected type syntax: type(non_negative_integer)"
  end

  defp do_core_quote_term({:refl, _meta, [value]}) do
    value = do_quote_term(value)

    quote do
      Theoria.Syntax.refl(unquote(value))
    end
  end

  defp do_core_quote_term({:eq_rec, _meta, [type, motive, base, proof]}) do
    type = do_quote_term(type)
    motive = do_quote_term(motive)
    base = do_quote_term(base)
    proof = do_quote_term(proof)

    quote do
      Theoria.Syntax.eq_rec(unquote(type), unquote(motive), unquote(base), unquote(proof))
    end
  end

  defp do_core_quote_term({operator, _meta, [domain, codomain]}) when operator in [:~>, :~>>] do
    domain = do_quote_term(domain)
    codomain = do_quote_term(codomain)

    quote do
      Theoria.Syntax.arrow(unquote(domain), unquote(codomain))
    end
  end

  defp do_core_quote_term({:arrow, _meta, [domain, codomain]}) do
    domain = do_quote_term(domain)
    codomain = do_quote_term(codomain)

    quote do
      Theoria.Syntax.arrow(unquote(domain), unquote(codomain))
    end
  end

  defp do_core_quote_term({:app, _meta, [fun, arg]}) do
    fun = do_quote_term(fun)
    arg = do_quote_term(arg)

    quote do
      Theoria.Syntax.app(unquote(fun), unquote(arg))
    end
  end

  defp do_core_quote_term({:forall, _meta, [name, domain, [do: body]]}) do
    domain = do_quote_term(domain)
    body = do_quote_term(body)

    quote do
      Theoria.Syntax.forall(unquote(quote_binder(name)), unquote(domain), unquote(body))
    end
  end

  defp do_core_quote_term({:forall, _meta, _args}) do
    raise ArgumentError,
          "expected forall binder syntax: forall :name, domain do ... end"
  end

  defp do_core_quote_term({:lam, _meta, [name, domain, [do: body]]}) do
    domain = do_quote_term(domain)
    body = do_quote_term(body)

    quote do
      Theoria.Syntax.lam(unquote(quote_binder(name)), unquote(domain), unquote(body))
    end
  end

  defp do_core_quote_term({:lam, _meta, _args}) do
    raise ArgumentError,
          "expected lambda binder syntax: lam :name, domain do ... end"
  end

  defp do_core_quote_term({:let, _meta, [name, type, value, [do: body]]}) do
    type = do_quote_term(type)
    value = do_quote_term(value)
    body = do_quote_term(body)

    quote do
      Theoria.Syntax.let(
        unquote(quote_binder(name)),
        unquote(type),
        unquote(value),
        unquote(body)
      )
    end
  end

  defp do_core_quote_term({:let, _meta, _args}) do
    raise ArgumentError,
          "expected let syntax: let :name, type, value do ... end"
  end

  defp do_core_quote_term({:eq, _meta, [type, left, right]}) do
    type = do_quote_term(type)
    left = do_quote_term(left)
    right = do_quote_term(right)

    quote do
      Theoria.Syntax.eq(unquote(type), unquote(left), unquote(right))
    end
  end

  defp do_core_quote_term({:__aliases__, _meta, parts}) do
    quote do
      Theoria.Syntax.const(unquote(Module.concat(parts)))
    end
  end

  defp do_core_quote_term({name, _meta, context}) when is_atom(name) and is_atom(context) do
    quote do
      Theoria.Syntax.var(unquote(name))
    end
  end

  defp do_core_quote_term({name, _meta, args}) when is_atom(name) and is_list(args) do
    quote_application(name, args)
  end

  defp do_core_quote_term(list) when is_list(list) do
    raise ArgumentError,
          "term blocks do not support Elixir lists; use list_nil/list_cons constants"
  end

  defp do_core_quote_term(tuple) when is_tuple(tuple) do
    raise ArgumentError,
          "term blocks do not support Elixir tuples; use explicit Theoria constructors"
  end

  defp do_core_quote_term(atom) when is_atom(atom) do
    quote do
      Theoria.Syntax.const(unquote(atom))
    end
  end

  defp do_core_quote_term(other) when is_binary(other) do
    raise ArgumentError, "term blocks do not support Elixir strings: #{inspect(other)}"
  end

  defp do_core_quote_term(other) when is_number(other) do
    raise ArgumentError, "term blocks do not support Elixir numbers: #{inspect(other)}"
  end

  defp quote_application(name, args) do
    args
    |> Enum.map(&do_quote_term/1)
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
