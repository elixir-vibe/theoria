defmodule Theoria.Library.Vec.TheoremsTest do
  use ExUnit.Case, async: true

  alias Theoria.Library.Vec
  alias Theoria.Library.Vec.Theorems
  alias Theoria.Theorem

  test "registers vec theorem names" do
    assert Theorems.__theoria_theorems__() == [
             :vec_nil_is_vec,
             :vec_cons_is_function,
             :vec_ind_nil_nat,
             :vec_ind_cons_nat
           ]
  end

  test "all vec theorems check under the vec environment" do
    {:ok, env} = Vec.env()

    for name <- Theorems.__theoria_theorems__() do
      theorem_fun = String.to_existing_atom("#{name}_theorem")
      assert {:ok, %Theorem{name: ^name}} = apply(Theorems, theorem_fun, [env])
    end
  end
end
