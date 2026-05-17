defmodule Theoria.Validation.InductiveChecks do
  @moduledoc "Built-in inductive specification checks for Theoria validation."

  alias Theoria.Env
  alias Theoria.Library.{Bool, List, Nat, Vec}
  alias Theoria.Validation.InductiveCheck

  @doc "Returns built-in inductive checks."
  @spec all() :: [InductiveCheck.t()]
  def all do
    empty = Env.new()
    {:ok, nat_env} = Nat.env()

    [
      InductiveCheck.new(:bool, :Bool, Bool.inductive_spec(), empty),
      InductiveCheck.new(:nat, :Nat, Nat.inductive_spec(), empty),
      InductiveCheck.new(:list, :List, List.inductive_spec(), nat_env),
      InductiveCheck.new(:vec, :Vec, Vec.inductive_spec(), nat_env)
    ]
  end
end
