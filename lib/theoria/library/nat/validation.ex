defmodule Theoria.Library.Nat.Validation do
  @moduledoc "Validation metadata for `Theoria.Library.Nat`."

  alias Theoria.Env
  alias Theoria.Library.Nat
  alias Theoria.Validation.{DefeqChecks, InductiveCheck, Library, TheoremModuleCheck}

  @doc "Returns validation checks owned by the Nat library."
  def checks do
    Library.new(
      TheoremModuleCheck.new(:nat, Nat.Theorems),
      by_category(:nat),
      [InductiveCheck.new(:nat, :Nat, Nat.inductive_spec(), Env.new())]
    )
  end

  defp by_category(category), do: Enum.filter(DefeqChecks.all(), &(&1.category == category))
end
