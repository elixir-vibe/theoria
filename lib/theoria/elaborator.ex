defmodule Theoria.Elaborator do
  @moduledoc """
  Converts named `Theoria.Syntax` terms to de Bruijn-indexed `Theoria.Term` terms.

  The elaborator is a convenience layer. It is intentionally untrusted: callers
  still need to pass elaborated terms through `Theoria.Kernel`.
  """

  alias Theoria.Error
  alias Theoria.Syntax
  alias Theoria.Syntax.{App, Const, Eq, Forall, Lam, Refl, Sort, Var}
  alias Theoria.Term

  @type result :: {:ok, Term.t()} | {:error, Error.t()}

  @spec elaborate(Syntax.t()) :: result()
  def elaborate(term), do: elaborate(term, [])

  @spec elaborate(Syntax.t(), [atom()]) :: result()
  def elaborate(%Sort{level: level}, _context), do: {:ok, Term.sort(level)}
  def elaborate(%Const{name: name}, _context), do: {:ok, Term.const(name)}

  def elaborate(%Var{name: name}, context) do
    case Enum.find_index(context, &(&1 == name)) do
      nil -> error(:unbound_name, name: name, context: context)
      index -> {:ok, Term.bvar(index)}
    end
  end

  def elaborate(%App{fun: fun, arg: arg}, context) do
    with {:ok, fun} <- elaborate(fun, context),
         {:ok, arg} <- elaborate(arg, context) do
      {:ok, Term.app(fun, arg)}
    end
  end

  def elaborate(%Lam{name: name, domain: domain, body: body}, context) do
    elaborate_binder(context, name, domain, body, &Term.lam/3)
  end

  def elaborate(%Forall{name: name, domain: domain, body: body}, context) do
    elaborate_binder(context, name, domain, body, &Term.forall/3)
  end

  def elaborate(%Eq{type: type, left: left, right: right}, context) do
    with {:ok, type} <- elaborate(type, context),
         {:ok, left} <- elaborate(left, context),
         {:ok, right} <- elaborate(right, context) do
      {:ok, Term.eq(type, left, right)}
    end
  end

  def elaborate(%Refl{value: value}, context) do
    with {:ok, value} <- elaborate(value, context) do
      {:ok, Term.refl(value)}
    end
  end

  @spec elaborate!(Syntax.t()) :: Term.t()
  def elaborate!(term) do
    case elaborate(term) do
      {:ok, term} -> term
      {:error, error} -> raise error
    end
  end

  defp elaborate_binder(context, name, domain, body, constructor) do
    with {:ok, domain} <- elaborate(domain, context),
         {:ok, body} <- elaborate(body, [name | context]) do
      {:ok, constructor.(name, domain, body)}
    end
  end

  defp error(reason, details), do: {:error, %Error{reason: reason, details: details}}
end
