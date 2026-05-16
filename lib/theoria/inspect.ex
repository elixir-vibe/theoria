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
    Theoria.Term.Eq,
    Theoria.Term.Refl
  ] do
  def inspect(term, _opts) do
    Theoria.Pretty.term(term)
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
