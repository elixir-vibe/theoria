defmodule Theoria.Normalize.FuelTest do
  use ExUnit.Case, async: true

  alias Theoria.Normalize.Fuel

  test "uses default max steps" do
    assert %Fuel{remaining_steps: 10_000, max_steps: 10_000} = Fuel.new()
  end

  test "uses custom max steps" do
    assert %Fuel{remaining_steps: 42, max_steps: 42} = Fuel.new(max_steps: 42)
  end

  test "spend decrements remaining steps" do
    fuel = Fuel.new(max_steps: 2)

    assert {:ok, %Fuel{remaining_steps: 1, max_steps: 2}} = Fuel.spend(fuel)
  end

  test "spend returns a pretty normalization limit error at zero" do
    fuel = %Fuel{remaining_steps: 0, max_steps: 2}

    assert {:error, error} = Fuel.spend(fuel)
    assert Exception.message(error) == "normalization exceeded limit of 2 steps"
  end
end
