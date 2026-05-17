defmodule Theoria.Rewrite do
  @moduledoc "Untrusted structural rewrite helpers over core terms."

  alias Theoria.Rewrite.Match
  alias Theoria.Rewrite.Rule
  alias Theoria.Term

  @type direction :: :forward | :backward

  @doc "Rewrites the first structural occurrence described by an equality term."
  @spec once(Term.t(), Term.Eq.t(), keyword()) :: {:ok, Term.t()} | :not_found
  def once(term, %Term.Eq{left: left, right: right}, opts \\ []) do
    case Keyword.get(opts, :direction, :forward) do
      :forward -> replace_once(term, left, right)
      :backward -> replace_once(term, right, left)
    end
  end

  @doc "Rewrites the first occurrence matched by a possibly schematic rewrite rule."
  @spec once_rule(Term.t(), Rule.t()) :: {:ok, Term.t()} | :not_found
  def once_rule(term, %Rule{equality: equality, direction: direction, binders: binders}) do
    binder_count = length(binders)

    case direction do
      :forward -> replace_once(term, equality.left, equality.right, binder_count)
      :backward -> replace_once(term, equality.right, equality.left, binder_count)
    end
  end

  @doc "Returns a rewrite direction atom after validation."
  @spec direction!(direction()) :: direction()
  def direction!(direction) when direction in [:forward, :backward], do: direction

  defp replace_once(term, from, to) when term == from, do: {:ok, to}
  defp replace_once(%Term.App{} = term, from, to), do: rewrite_app(term, from, to)
  defp replace_once(%Term.Lam{} = term, from, to), do: rewrite_lam(term, from, to)
  defp replace_once(%Term.Forall{} = term, from, to), do: rewrite_forall(term, from, to)
  defp replace_once(%Term.Let{} = term, from, to), do: rewrite_let(term, from, to)
  defp replace_once(%Term.Eq{} = term, from, to), do: rewrite_eq(term, from, to)
  defp replace_once(%Term.Refl{} = term, from, to), do: rewrite_refl(term, from, to)
  defp replace_once(%Term.EqRec{} = term, from, to), do: rewrite_eq_rec(term, from, to)
  defp replace_once(_term, _from, _to), do: :not_found

  defp replace_once(term, from, to, binder_count) do
    case Match.match(from, term, binder_count) do
      {:ok, substitution} -> {:ok, Match.instantiate(to, substitution)}
      :error -> replace_child_once(term, from, to, binder_count)
    end
  end

  defp replace_child_once(%Term.App{} = term, from, to, binder_count),
    do: rewrite_app(term, from, to, binder_count)

  defp replace_child_once(%Term.Lam{} = term, from, to, binder_count),
    do: rewrite_lam(term, from, to, binder_count)

  defp replace_child_once(%Term.Forall{} = term, from, to, binder_count),
    do: rewrite_forall(term, from, to, binder_count)

  defp replace_child_once(%Term.Let{} = term, from, to, binder_count),
    do: rewrite_let(term, from, to, binder_count)

  defp replace_child_once(%Term.Eq{} = term, from, to, binder_count),
    do: rewrite_eq(term, from, to, binder_count)

  defp replace_child_once(%Term.Refl{} = term, from, to, binder_count),
    do: rewrite_refl(term, from, to, binder_count)

  defp replace_child_once(%Term.EqRec{} = term, from, to, binder_count),
    do: rewrite_eq_rec(term, from, to, binder_count)

  defp replace_child_once(_term, _from, _to, _binder_count), do: :not_found

  defp rewrite_app(%Term.App{} = term, from, to) do
    case replace_once(term.fun, from, to) do
      {:ok, fun} -> {:ok, %Term.App{term | fun: fun}}
      :not_found -> rewrite_app_arg(term, from, to)
    end
  end

  defp rewrite_app_arg(%Term.App{} = term, from, to) do
    case replace_once(term.arg, from, to) do
      {:ok, arg} -> {:ok, %Term.App{term | arg: arg}}
      :not_found -> :not_found
    end
  end

  defp rewrite_lam(%Term.Lam{} = term, from, to),
    do: rewrite_binder(term, [:domain, :body], from, to)

  defp rewrite_forall(%Term.Forall{} = term, from, to),
    do: rewrite_binder(term, [:domain, :body], from, to)

  defp rewrite_let(%Term.Let{} = term, from, to),
    do: rewrite_fields(term, [:type, :value, :body], from, to)

  defp rewrite_eq(%Term.Eq{} = term, from, to),
    do: rewrite_fields(term, [:type, :left, :right], from, to)

  defp rewrite_refl(%Term.Refl{} = term, from, to), do: rewrite_fields(term, [:value], from, to)

  defp rewrite_eq_rec(%Term.EqRec{} = term, from, to),
    do: rewrite_fields(term, [:type, :motive, :base, :proof], from, to)

  defp rewrite_binder(term, fields, from, to), do: rewrite_fields(term, fields, from, to)

  defp rewrite_fields(term, fields, from, to) do
    Enum.reduce_while(fields, :not_found, fn field, :not_found ->
      case replace_once(Map.fetch!(term, field), from, to) do
        {:ok, value} -> {:halt, {:ok, Map.put(term, field, value)}}
        :not_found -> {:cont, :not_found}
      end
    end)
  end

  defp rewrite_app(%Term.App{} = term, from, to, binder_count) do
    case replace_once(term.fun, from, to, binder_count) do
      {:ok, fun} -> {:ok, %Term.App{term | fun: fun}}
      :not_found -> rewrite_app_arg(term, from, to, binder_count)
    end
  end

  defp rewrite_app_arg(%Term.App{} = term, from, to, binder_count) do
    case replace_once(term.arg, from, to, binder_count) do
      {:ok, arg} -> {:ok, %Term.App{term | arg: arg}}
      :not_found -> :not_found
    end
  end

  defp rewrite_lam(%Term.Lam{} = term, from, to, binder_count),
    do: rewrite_fields(term, [:domain, :body], from, to, binder_count)

  defp rewrite_forall(%Term.Forall{} = term, from, to, binder_count),
    do: rewrite_fields(term, [:domain, :body], from, to, binder_count)

  defp rewrite_let(%Term.Let{} = term, from, to, binder_count),
    do: rewrite_fields(term, [:type, :value, :body], from, to, binder_count)

  defp rewrite_eq(%Term.Eq{} = term, from, to, binder_count),
    do: rewrite_fields(term, [:type, :left, :right], from, to, binder_count)

  defp rewrite_refl(%Term.Refl{} = term, from, to, binder_count),
    do: rewrite_fields(term, [:value], from, to, binder_count)

  defp rewrite_eq_rec(%Term.EqRec{} = term, from, to, binder_count),
    do: rewrite_fields(term, [:type, :motive, :base, :proof], from, to, binder_count)

  defp rewrite_fields(term, fields, from, to, binder_count) do
    Enum.reduce_while(fields, :not_found, fn field, :not_found ->
      case replace_once(Map.fetch!(term, field), from, to, binder_count) do
        {:ok, value} -> {:halt, {:ok, Map.put(term, field, value)}}
        :not_found -> {:cont, :not_found}
      end
    end)
  end
end
