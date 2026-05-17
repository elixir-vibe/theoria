defmodule Theoria.Library.List.TheoremsTest do
  use ExUnit.Case, async: true

  alias Theoria.Library.List
  alias Theoria.Library.List.Theorems
  alias Theoria.Theorem

  test "registers list theorem names" do
    assert Theorems.__theoria_theorems__() == [
             :list_nil_is_list,
             :list_cons_is_function,
             :list_length_nil,
             :list_length_singleton,
             :list_length_cons_nil,
             :list_length_cons,
             :list_append_nil_left,
             :list_append_cons_left,
             :list_length_two
           ]
  end

  test "all list theorems check under the list environment" do
    {:ok, env} = List.env()

    for name <- Theorems.__theoria_theorems__() do
      theorem_fun = String.to_existing_atom("#{name}_theorem")
      assert {:ok, %Theorem{name: ^name}} = apply(Theorems, theorem_fun, [env])
    end
  end
end
