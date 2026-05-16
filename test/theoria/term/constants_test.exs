defmodule Theoria.Term.ConstantsTest do
  use ExUnit.Case, async: true

  alias Theoria.Term

  import Theoria.Term

  test "collects constants from applications" do
    term = app(const(:f), app(const(:g), bvar(0)))

    assert Term.constants(term) == MapSet.new([:f, :g])
  end

  test "collects constants from binders" do
    term = forall(:x, const(:A), lam(:y, const(:B), app(const(:f), bvar(1))))

    assert Term.constants(term) == MapSet.new([:A, :B, :f])
  end

  test "collects constants from equality and reflexivity" do
    term = eq(const(:A), refl(const(:x)), const(:y))

    assert Term.constants(term) == MapSet.new([:A, :x, :y])
  end

  test "collects constants from lets" do
    term = let(:x, const(:A), const(:a), app(const(:f), bvar(0)))

    assert Term.constants(term) == MapSet.new([:A, :a, :f])
  end

  test "sorts and bound variables have no dependencies" do
    assert Term.constants(sort(0)) == MapSet.new()
    assert Term.constants(bvar(0)) == MapSet.new()
  end
end
