defmodule Theoria.DSL.Quote.Prelude do
  @moduledoc "Prelude-specific term quote sugar."

  @spec quote_term(Macro.t(), (Macro.t() -> Macro.t())) :: {:ok, Macro.t()} | :error
  def quote_term({:bool_true, _meta, []}, _quote_term), do: ok_const(true)
  def quote_term({:bool_false, _meta, []}, _quote_term), do: ok_const(false)
  def quote_term({:bool, _meta, []}, _quote_term), do: ok_const(:Bool)
  def quote_term({:nat, _meta, []}, _quote_term), do: ok_const(:Nat)
  def quote_term({:true_prop, _meta, []}, _quote_term), do: ok_const(:True)
  def quote_term({:false_prop, _meta, []}, _quote_term), do: ok_const(:False)
  def quote_term({:zero, _meta, context}, _quote_term) when is_atom(context), do: ok_const(:zero)
  def quote_term({:succ, _meta, context}, _quote_term) when is_atom(context), do: ok_const(:succ)

  def quote_term({:list, _meta, [element_type]}, quote_term) do
    {:ok, quote_level_application(:List, [1], [element_type], quote_term)}
  end

  def quote_term({:list, _meta, [element_type, level]}, quote_term) do
    {:ok, quote_level_application(:List, [level], [element_type], quote_term)}
  end

  def quote_term({:vec, _meta, [element_type, length]}, quote_term) do
    {:ok, quote_level_application(:Vec, [1], [element_type, length], quote_term)}
  end

  def quote_term({:vec, _meta, [element_type, length, level]}, quote_term) do
    {:ok, quote_level_application(:Vec, [level], [element_type, length], quote_term)}
  end

  def quote_term({name, _meta, context}, _quote_term)
      when name in [:list_nil, :list_cons, :vec_nil, :vec_cons] and is_atom(context) do
    {:ok, quote_const(name, [1])}
  end

  def quote_term({name, _meta, args}, quote_term)
      when name in [:bool_rec, :bool_ind, :nat_rec, :nat_ind] and is_list(args) do
    {:ok, quote_level_application(name, [1], args, quote_term)}
  end

  def quote_term({name, _meta, args}, quote_term)
      when name in [:list_nil, :list_cons, :list_length, :list_append, :vec_nil, :vec_cons] and
             is_list(args) do
    {:ok, quote_level_application(name, [1], args, quote_term)}
  end

  def quote_term({name, _meta, args}, quote_term)
      when name in [:list_rec, :list_ind] and is_list(args) do
    {:ok, quote_level_application(name, [1, 1], args, quote_term)}
  end

  def quote_term({:vec_ind, _meta, args}, quote_term) when is_list(args) do
    {:ok, quote_level_application(:vec_ind, [1], args, quote_term)}
  end

  def quote_term({:neg, _meta, [proposition]}, quote_term) do
    {:ok, quote_application(:not, [proposition], quote_term)}
  end

  def quote_term({:conj, _meta, [left, right]}, quote_term) do
    {:ok, quote_application(:and, [left, right], quote_term)}
  end

  def quote_term({:__aliases__, _meta, [:Bool]}, _quote_term) do
    raise ArgumentError, "use bool() for the Theoria Bool type inside term blocks"
  end

  def quote_term({:__aliases__, _meta, [:Nat]}, _quote_term) do
    raise ArgumentError, "use nat() for the Theoria Nat type inside term blocks"
  end

  def quote_term({:__aliases__, _meta, [:List]}, _quote_term) do
    raise ArgumentError, "use list(element_type) for the Theoria List type inside term blocks"
  end

  def quote_term(_ast, _quote_term), do: :error

  defp ok_const(name), do: {:ok, quote_const(name)}

  defp quote_application(name, args, quote_term) do
    args
    |> Enum.map(quote_term)
    |> Enum.reduce(quote_const(name), fn arg, fun ->
      quote do
        Theoria.Syntax.app(unquote(fun), unquote(arg))
      end
    end)
  end

  defp quote_level_application(name, levels, args, quote_term) do
    args
    |> Enum.map(quote_term)
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
end
