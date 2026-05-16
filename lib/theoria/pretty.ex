defmodule Theoria.Pretty do
  @moduledoc "Human-readable rendering for Theoria values."

  alias Theoria.Term
  alias Theoria.Term.{App, BVar, Const, Eq, Forall, Lam, Refl, Sort}
  alias Theoria.Theorem

  @spec term(Term.t()) :: String.t()
  def term(term), do: render_term(term, [])

  @spec theorem(Theorem.t()) :: String.t()
  def theorem(%Theorem{name: name, type: type}) do
    "theorem #{name} : #{term(type)}"
  end

  defp render_term(%Sort{level: 0}, _context), do: "Prop"
  defp render_term(%Sort{level: level}, _context), do: "Type #{level}"

  defp render_term(%BVar{index: index}, context) do
    Enum.at(context, index) || "##{index}"
  end

  defp render_term(%Const{name: name}, _context), do: Atom.to_string(name)

  defp render_term(%App{} = app, context) do
    {fun, args} = collect_app(app, [])

    ([render_atomic(fun, context)] ++ Enum.map(args, &render_atomic(&1, context)))
    |> Enum.join(" ")
  end

  defp render_term(%Lam{name: name, domain: domain, body: body}, context) do
    rendered_name = binder_name(name)
    extended = [rendered_name | context]
    "λ #{rendered_name} : #{render_term(domain, context)}, #{render_term(body, extended)}"
  end

  defp render_term(%Forall{name: :_, domain: domain, body: body}, context) do
    "#{render_atomic(domain, context)} → #{render_term(body, ["_" | context])}"
  end

  defp render_term(%Forall{name: name, domain: domain, body: body}, context) do
    rendered_name = binder_name(name)
    extended = [rendered_name | context]
    "∀ #{rendered_name} : #{render_term(domain, context)}, #{render_term(body, extended)}"
  end

  defp render_term(%Eq{left: left, right: right}, context) do
    "#{render_atomic(left, context)} = #{render_atomic(right, context)}"
  end

  defp render_term(%Refl{value: value}, context) do
    "refl #{render_atomic(value, context)}"
  end

  defp render_atomic(%Sort{} = term, context), do: render_term(term, context)
  defp render_atomic(%BVar{} = term, context), do: render_term(term, context)
  defp render_atomic(%Const{} = term, context), do: render_term(term, context)
  defp render_atomic(%App{} = term, context), do: render_term(term, context)
  defp render_atomic(term, context), do: "(" <> render_term(term, context) <> ")"

  defp collect_app(%App{fun: fun, arg: arg}, args), do: collect_app(fun, [arg | args])
  defp collect_app(fun, args), do: {fun, args}

  defp binder_name(:_), do: "_"
  defp binder_name(name), do: Atom.to_string(name)
end
