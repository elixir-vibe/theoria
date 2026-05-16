defmodule Theoria.Library.Bool.TheoremsTest do
  use ExUnit.Case, async: true

  alias Theoria.Library.Bool
  alias Theoria.Library.Bool.Theorems
  alias Theoria.Theorem

  test "registers bool theorem names" do
    assert Theorems.__theoria_theorems__() == [
             :true_is_bool,
             :false_is_bool,
             :bool_not_is_function,
             :bool_not_true,
             :bool_not_false,
             :bool_and_true_true,
             :bool_and_false_true
           ]
  end

  test "all bool theorems check under the bool environment" do
    {:ok, env} = Bool.env()

    for name <- Theorems.__theoria_theorems__() do
      theorem_fun = String.to_existing_atom("#{name}_theorem")
      assert {:ok, %Theorem{name: ^name}} = apply(Theorems, theorem_fun, [env])
    end
  end
end
