defmodule Theoria.Library.Vec.Validation do
  @moduledoc "Validation metadata for `Theoria.Library.Vec`."

  alias Theoria.Library.{Nat, Vec}
  alias Theoria.Validation.{DefeqChecks, InductiveCheck, Library, TheoremModuleCheck}

  @doc "Returns validation checks owned by the Vec library."
  def checks do
    {:ok, nat_env} = Nat.env()

    Library.new(
      TheoremModuleCheck.new(:vec, Vec.Theorems),
      by_category(:vec),
      [InductiveCheck.new(:vec, :Vec, Vec.inductive_spec(), nat_env)]
    )
  end

  defp by_category(category), do: Enum.filter(DefeqChecks.all(), &(&1.category == category))
end
