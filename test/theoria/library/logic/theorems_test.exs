defmodule Theoria.Library.Logic.TheoremsTest do
  use ExUnit.Case, async: true

  alias Theoria.Library.Logic
  alias Theoria.Library.Logic.Theorems
  alias Theoria.Theorem

  test "registers proof corpus theorem names" do
    assert Theorems.__theoria_theorems__() == [
             :identity,
             :false_elim_eta
           ]
  end

  test "all logic theorems check under the logic environment" do
    {:ok, env} = Logic.env()

    for name <- Theorems.__theoria_theorems__() do
      theorem_fun = String.to_existing_atom("#{name}_theorem")
      assert {:ok, %Theorem{name: ^name}} = apply(Theorems, theorem_fun, [env])
    end
  end

  test "logic constants are required for theorem checking" do
    assert {:error, error} = Theorems.false_elim_eta_theorem()
    assert error.reason == :unknown_constant
  end
end
