defmodule Theoria.Validation.Core do
  @moduledoc "Core calculus validation checks."

  alias Theoria.Term
  alias Theoria.Validation.DefeqCheck

  @doc "Returns core definitional-equality checks not owned by a library."
  @spec defeq_checks() :: [DefeqCheck.t()]
  def defeq_checks do
    nat = Term.const(:Nat)
    type = Term.sort(1)
    var = Term.bvar(0)

    [
      DefeqCheck.new(:defeq, "beta_identity", Term.app(Term.lam(:x, type, var), nat), nat),
      DefeqCheck.new(:defeq, "zeta_identity", Term.let(:x, type, nat, var), nat)
    ]
  end
end
