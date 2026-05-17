defmodule Theoria.Library.Bool.Validation do
  @moduledoc "Validation metadata for `Theoria.Library.Bool`."

  alias Theoria.Env
  alias Theoria.Library.Bool
  alias Theoria.Validation.{DefeqChecks, InductiveCheck, Library, TheoremModuleCheck}

  @doc "Returns validation checks owned by the Bool library."
  def checks do
    Library.new(
      TheoremModuleCheck.new(:bool, Bool.Theorems),
      by_category(:bool),
      [InductiveCheck.new(:bool, :Bool, Bool.inductive_spec(), Env.new())]
    )
  end

  defp by_category(category), do: Enum.filter(DefeqChecks.all(), &(&1.category == category))
end
