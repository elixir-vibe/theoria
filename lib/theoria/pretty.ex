defmodule Theoria.Pretty do
  @moduledoc "Human-readable rendering for Theoria values."

  alias Theoria.Error
  alias Theoria.Kernel.TrustReport
  alias Theoria.Term
  alias Theoria.Term.{App, BVar, Const, Eq, Forall, Lam, Let, Refl, Sort}
  alias Theoria.Theorem

  @spec term(Term.t()) :: String.t()
  def term(term), do: render_term(term, [])

  @spec theorem(Theorem.t()) :: String.t()
  def theorem(%Theorem{name: name, type: type}) do
    "theorem #{name} : #{term(type)}"
  end

  @spec trust_report(TrustReport.t()) :: String.t()
  def trust_report(%TrustReport{} = report) do
    [
      "trust #{report.name} : #{report.kind}",
      "axioms: #{render_names(report.axioms)}",
      "deps: #{render_names(report.transitive_dependencies)}"
    ]
    |> Enum.join(", ")
  end

  @spec level(Theoria.Level.t()) :: String.t()
  def level(level), do: render_level(level)

  @spec error(Error.t()) :: String.t()
  def error(%Error{reason: :type_mismatch, details: details}) do
    actual = Keyword.fetch!(details, :left)
    expected = Keyword.fetch!(details, :right)

    "type mismatch\n\nactual:\n  #{term(actual)}\n\nexpected:\n  #{term(expected)}"
  end

  def error(%Error{reason: :lambda_domain_mismatch, details: details}) do
    actual = Keyword.fetch!(details, :left)
    expected = Keyword.fetch!(details, :right)

    "lambda domain mismatch\n\nactual domain:\n  #{term(actual)}\n\nexpected domain:\n  #{term(expected)}"
  end

  def error(%Error{reason: :unbound_variable, details: details}) do
    index = Keyword.fetch!(details, :index)
    context_size = Keyword.fetch!(details, :context_size)
    "unbound de Bruijn variable ##{index} in context of size #{context_size}"
  end

  def error(%Error{reason: :unknown_constant, details: details}) do
    name = Keyword.fetch!(details, :name)
    "unknown constant: #{name}"
  end

  def error(%Error{reason: :not_a_function, details: details}) do
    type = Keyword.fetch!(details, :type)
    "expected a function type, got:\n  #{term(type)}"
  end

  def error(%Error{reason: :expected_sort, details: details}) do
    type = Keyword.fetch!(details, :type)
    "expected a type/sort, got:\n  #{term(type)}"
  end

  def error(%Error{reason: :unbound_name, details: details}) do
    name = Keyword.fetch!(details, :name)
    context = Keyword.get(details, :context, [])
    "unbound name: #{name} (context: #{inspect(context)})"
  end

  def error(%Error{reason: :normalization_limit, details: details}) do
    max_steps = Keyword.fetch!(details, :max_steps)
    "normalization exceeded limit of #{max_steps} steps"
  end

  def error(%Error{reason: :duplicate_declaration, details: details}) do
    name = Keyword.fetch!(details, :name)
    "duplicate declaration: #{name}"
  end

  def error(%Error{reason: :missing_declaration, details: details}) do
    name = Keyword.fetch!(details, :name)
    "missing declaration: #{name}"
  end

  def error(%Error{reason: :untracked_declaration, details: details}) do
    name = Keyword.fetch!(details, :name)
    "untracked declaration: #{name}"
  end

  def error(%Error{reason: :duplicate_declaration_index}) do
    "environment declaration index contains duplicates"
  end

  def error(%Error{reason: :invalid_declaration, details: details}) do
    name = Keyword.fetch!(details, :name)
    "invalid declaration: #{name}"
  end

  def error(%Error{reason: :universe_arity_mismatch, details: details}) do
    expected = Keyword.fetch!(details, :expected)
    actual = Keyword.fetch!(details, :actual)
    "universe argument mismatch: expected #{expected}, got #{actual}"
  end

  def error(%Error{reason: :unknown_universe_parameter, details: details}) do
    params = details |> Keyword.fetch!(:params) |> Enum.join(", ")
    "unknown universe parameter(s): #{params}"
  end

  def error(%Error{reason: :invalid_universe_parameters, details: details}) do
    "invalid universe parameter list: #{inspect(Keyword.fetch!(details, :params))}"
  end

  def error(%Error{reason: :duplicate_universe_parameter, details: details}) do
    "duplicate universe parameter in: #{inspect(Keyword.fetch!(details, :params))}"
  end

  def error(%Error{reason: reason, details: details}) do
    "#{reason}: #{inspect(details)}"
  end

  defp render_term(%Sort{level: level}, _context) do
    case Theoria.Level.to_integer(level) do
      {:ok, 0} -> "Prop"
      {:ok, level} -> "Type #{level}"
      :error -> "Sort #{render_level(level)}"
    end
  end

  defp render_term(%BVar{index: index}, context) do
    Enum.at(context, index) || "##{index}"
  end

  defp render_term(%Const{name: name, levels: []}, _context), do: Atom.to_string(name)

  defp render_term(%Const{name: name, levels: levels}, _context) do
    rendered_levels = Enum.map_join(levels, ", ", &render_level/1)
    "#{name}.#{rendered_levels}"
  end

  defp render_term(%App{} = app, context) do
    {fun, args} = Term.Application.collect(app)

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

  defp render_term(%Let{name: name, type: type, value: value, body: body}, context) do
    rendered_name = binder_name(name)
    extended = [rendered_name | context]

    "let #{rendered_name} : #{render_term(type, context)} := #{render_term(value, context)} in #{render_term(body, extended)}"
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

  defp render_level(level) do
    level = Theoria.Level.normalize(level)

    case Theoria.Level.to_integer(level) do
      {:ok, level} -> Integer.to_string(level)
      :error -> do_render_level(level)
    end
  end

  defp do_render_level(%Theoria.Level.Zero{}), do: "0"
  defp do_render_level(%Theoria.Level.Param{name: name}), do: Atom.to_string(name)
  defp do_render_level(%Theoria.Level.Succ{level: level}), do: "succ(#{render_level(level)})"

  defp do_render_level(%Theoria.Level.Max{left: left, right: right}) do
    "max(#{render_level(left)}, #{render_level(right)})"
  end

  defp render_names(names) do
    names
    |> Enum.sort()
    |> case do
      [] -> "none"
      names -> Enum.map_join(names, ", ", &Atom.to_string/1)
    end
  end

  defp binder_name(:_), do: "_"
  defp binder_name(name), do: Atom.to_string(name)
end
