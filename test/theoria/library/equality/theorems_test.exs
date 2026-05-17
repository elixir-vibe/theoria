defmodule Theoria.Library.Equality.TheoremsTest do
  use ExUnit.Case, async: true

  alias Theoria.Library.Equality.Theorems
  alias Theoria.Theorem

  test "registers equality theorem names" do
    assert Theorems.__theoria_theorems__() == [
             :eq_refl,
             :eq_symm,
             :eq_trans,
             :eq_subst,
             :eq_ndrec,
             :eq_congr
           ]
  end

  test "all equality theorems check under the empty environment" do
    env = Theoria.new_env()

    for name <- Theorems.__theoria_theorems__() do
      theorem_fun = String.to_existing_atom("#{name}_theorem")
      assert {:ok, %Theorem{name: ^name}} = apply(Theorems, theorem_fun, [env])
    end
  end
end
