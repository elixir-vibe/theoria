defmodule Theoria.Library.List.Validation do
  @moduledoc "Validation metadata for `Theoria.Library.List`."

  alias Theoria.Library.{List, Nat}
  alias Theoria.Validation.{DefeqChecks, InductiveCheck, Library, TheoremModuleCheck}

  @doc "Returns validation checks owned by the List library."
  def checks do
    {:ok, nat_env} = Nat.env()

    Library.new(
      TheoremModuleCheck.new(:list, List.Theorems),
      by_category(:list),
      [InductiveCheck.new(:list, :List, List.inductive_spec(), nat_env)]
    )
  end

  defp by_category(category), do: Enum.filter(DefeqChecks.all(), &(&1.category == category))
end
