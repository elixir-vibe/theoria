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
