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

defimpl Inspect, for: Theoria.Env.Matcher do
  import Inspect.Algebra

  def inspect(matcher, _opts) do
    concat([
      "#Theoria.EnvMatcher<",
      Atom.to_string(matcher.name),
      ", source: ",
      Atom.to_string(matcher.source),
      ", mode: #{matcher.mode}, checked, equations: #{length(matcher.equation_names)}",
      ">"
    ])
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

defimpl Inspect, for: Theoria.Equation.Extension.Registry do
  import Inspect.Algebra

  def inspect(registry, _opts) do
    concat([
      "#Theoria.EquationRegistry<",
      "definitions: #{map_size(registry.definitions)}, matchers: #{map_size(registry.matchers)}, theorems: #{map_size(registry.theorem_sources)}",
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Equation.MatcherDescriptor do
  import Inspect.Algebra

  def inspect(descriptor, _opts) do
    concat([
      "#Theoria.MatcherDescriptor<",
      Atom.to_string(descriptor.family),
      ", discrs: #{length(descriptor.discriminants)}, alts: #{length(descriptor.alternatives)}, recursor: ",
      Atom.to_string(descriptor.recursor),
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Equation.MatcherDescriptor.Alternative do
  import Inspect.Algebra

  def inspect(alternative, _opts) do
    concat(["#Theoria.MatcherDescriptorAlt<", inspect(alternative.name), ">"])
  end
end

defimpl Inspect, for: Theoria.Equation.MatcherEquation do
  import Inspect.Algebra

  def inspect(equation, _opts) do
    concat([
      "#Theoria.MatcherEquation<",
      Atom.to_string(equation.name),
      ", matcher: ",
      Atom.to_string(equation.matcher),
      ", constructor: ",
      inspect(equation.constructor),
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Equation.Signature do
  import Inspect.Algebra

  def inspect(signature, _opts) do
    concat([
      "#Theoria.EquationSignature<",
      Atom.to_string(signature.name),
      ", family: #{signature.family}, rec_arg: #{signature.rec_arg_pos}",
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Equation.CaseTemplate do
  import Inspect.Algebra

  def inspect(template, _opts) do
    suffix = template.suffix || :default

    concat([
      "#Theoria.CaseTemplate<",
      inspect(suffix),
      ", binders: #{length(template.binders)}",
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Equation.Compiled do
  import Inspect.Algebra

  def inspect(compiled, _opts) do
    concat([
      "#Theoria.CompiledEquation<",
      "family: #{compiled.schema.family}, clauses: #{length(compiled.clauses)}, rec_arg: #{compiled.rec_arg_pos}",
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Equation.Schema do
  import Inspect.Algebra

  def inspect(schema, _opts) do
    concat([
      "#Theoria.EquationSchema<",
      "family: #{schema.family}, equations: #{length(schema.equations)}",
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Equation.Schema.Equation do
  import Inspect.Algebra

  def inspect(equation, _opts) do
    concat(["#Theoria.EquationSchema.Case<", inspect(equation.suffix), ">"])
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

defimpl Inspect, for: Theoria.Equation.MatcherInfo.Discriminant do
  import Inspect.Algebra

  def inspect(discriminant, _opts) do
    label = discriminant.name || :anonymous

    concat([
      "#Theoria.MatcherDiscriminant<",
      inspect(label),
      ", position: #{inspect(discriminant.position)}, family: #{inspect(discriminant.family)}",
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Simp.Rule do
  import Inspect.Algebra

  def inspect(rule, _opts) do
    concat([
      "#Theoria.SimpRule<",
      Atom.to_string(rule.rewrite.name),
      ", priority: #{rule.priority}, source: #{rule.source}",
      ">"
    ])
  end
end

defimpl Inspect, for: Theoria.Simp.Database do
  import Inspect.Algebra

  def inspect(database, _opts) do
    concat(["#Theoria.SimpDatabase<", "#{length(database.rules)} rule(s)", ">"])
  end
end

defimpl Inspect, for: Theoria.Simp.Step do
  import Inspect.Algebra

  def inspect(step, _opts) do
    concat(["#Theoria.SimpStep<", Atom.to_string(step.rule), ", source: #{step.source}", ">"])
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
