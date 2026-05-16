defmodule Theoria.Library.Nat.TheoremsTest do
  use ExUnit.Case, async: true

  alias Theoria.Library.Nat
  alias Theoria.Library.Nat.Theorems
  alias Theoria.Theorem

  test "registers nat theorem names" do
    assert Theorems.__theoria_theorems__() == [
             :zero_is_nat,
             :succ_is_function,
             :nat_add_zero_left,
             :nat_add_one_left,
             :nat_add_one_zero,
             :nat_add_two_zero
           ]
  end

  test "all nat theorems check under the nat environment" do
    {:ok, env} = Nat.env()

    for name <- Theorems.__theoria_theorems__() do
      theorem_fun = String.to_existing_atom("#{name}_theorem")
      assert {:ok, %Theorem{name: ^name}} = apply(Theorems, theorem_fun, [env])
    end
  end
end
