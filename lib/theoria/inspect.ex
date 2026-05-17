defmodule Theoria.Inspect do
  @moduledoc false

  import Inspect.Algebra

  def doc(pretty) do
    concat(["#Theoria<", pretty, ">"])
  end
end

defimpl Inspect,
  for: [
    Theoria.Term.Sort,
    Theoria.Term.BVar,
    Theoria.Term.Const,
    Theoria.Term.App,
    Theoria.Term.Lam,
    Theoria.Term.Forall,
    Theoria.Term.Let,
    Theoria.Term.Eq,
    Theoria.Term.Refl,
    Theoria.Term.EqRec
  ] do
  def inspect(term, _opts) do
    Theoria.Pretty.term(term)
    |> Theoria.Inspect.doc()
  end
end

defimpl Inspect,
  for: [
    Theoria.Level.Zero,
    Theoria.Level.Succ,
    Theoria.Level.Max,
    Theoria.Level.Param
  ] do
  def inspect(level, _opts) do
    level
    |> Theoria.Pretty.level()
    |> then(&"level #{&1}")
    |> Theoria.Inspect.doc()
  end
end

defimpl Inspect, for: Theoria.Theorem do
  def inspect(theorem, _opts) do
    theorem
    |> Theoria.Pretty.theorem()
    |> Theoria.Inspect.doc()
  end
end

defimpl Inspect, for: Theoria.Kernel.TrustReport do
  def inspect(report, _opts) do
    report
    |> Theoria.Pretty.trust_report()
    |> Theoria.Inspect.doc()
  end
end

defimpl Inspect, for: Theoria.Inductive.Report do
  def inspect(report, _opts) do
    report
    |> Theoria.Pretty.inductive_report()
    |> Theoria.Inspect.doc()
  end
end

defimpl Inspect, for: Theoria.Inductive.Parameter do
  def inspect(parameter, _opts) do
    parameter
    |> Theoria.Pretty.inductive_parameter()
    |> Theoria.Inspect.doc()
  end
end

defimpl Inspect, for: Theoria.Inductive.Index do
  def inspect(index, _opts) do
    index
    |> Theoria.Pretty.inductive_index()
    |> Theoria.Inspect.doc()
  end
end

defimpl Inspect, for: Theoria.Inductive.Shape do
  def inspect(shape, _opts) do
    shape
    |> Theoria.Pretty.inductive_shape()
    |> Theoria.Inspect.doc()
  end
end

defimpl Inspect, for: Theoria.Equation.Info do
  import Inspect.Algebra

  def inspect(info, _opts) do
    parts = [
      Atom.to_string(info.name),
      "rec_arg: #{inspect(info.rec_arg_pos)}",
      "fixed: #{inspect(info.fixed_params.positions)}"
    ]

    parts =
      if info.level_params == [] do
        parts
      else
        parts ++ ["levels: #{inspect(info.level_params)}"]
      end

    parts
    |> Enum.join(", ")
    |> then(&concat(["#Theoria.EquationInfo<", &1, ">"]))
  end
end

defimpl Inspect, for: Theoria.Equation.FixedParams do
  import Inspect.Algebra

  def inspect(fixed_params, _opts) do
    concat(["#Theoria.FixedParams<", inspect(fixed_params.positions), ">"])
  end
end

defimpl Inspect, for: Theoria.Equation.Lemma do
  import Inspect.Algebra

  def inspect(lemma, _opts) do
    concat(["#Theoria.EquationLemma<", Atom.to_string(lemma.name), ">"])
  end
end

defimpl Inspect, for: Theoria.Equation.MatcherInfo do
  import Inspect.Algebra

  def inspect(info, _opts) do
    concat([
      "#Theoria.MatcherInfo<",
      Atom.to_string(info.name),
      ", discrs: #{info.num_discriminants}, alts: #{length(info.alternatives)}",
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Equation.MatcherInfo.Alternative do
  import Inspect.Algebra

  def inspect(alternative, _opts) do
    concat([
      "#Theoria.MatcherAlt<",
      Atom.to_string(alternative.constructor),
      ", fields: #{alternative.num_fields}",
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Rewrite.Rule do
  import Inspect.Algebra

  def inspect(rule, _opts) do
    concat([
      "#Theoria.RewriteRule<",
      Atom.to_string(rule.name),
      " #{rule.direction}",
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Rewrite.Database do
  import Inspect.Algebra

  def inspect(database, _opts) do
    concat(["#Theoria.RewriteDatabase<", "#{length(database.rules)} rule(s)", ">"])
  end
end
