defmodule Theoria.Spec.TypespecTest do
  use ExUnit.Case, async: true

  alias Theoria.Spec.Typespec
  alias Theoria.Typespec.Contract
  alias Theoria.Typespec.Type

  test "checks shallow type compatibility" do
    integer = %Type{kind: :integer}
    nat = %Type{kind: :non_neg_integer}
    string = %Type{kind: :string}

    assert Typespec.compatible?(integer, nat)
    refute Typespec.compatible?(nat, integer)

    compatibility = Typespec.compatibility(string, integer)
    refute Typespec.Compatibility.compatible?(compatibility)
    assert Typespec.Compatibility.reason(compatibility) == :different_type_shape
  end

  test "checks union coverage" do
    ok_user = %Type{kind: :tagged_tuple, value: :ok, args: [%Type{kind: :struct, module: User}]}
    error_atom = %Type{kind: :tagged_tuple, value: :error, args: [%Type{kind: :atom}]}
    old = %Type{kind: :union, args: [ok_user, error_atom]}
    new = ok_user

    assert Typespec.compatible?(old, new)

    new_error = %Type{kind: :tagged_tuple, value: :error, args: [%Type{kind: :string}]}
    refute Typespec.compatible?(old, new_error)
  end

  test "checks contract compatibility" do
    old = %Contract{
      module: Example,
      function: :fetch,
      arity: 1,
      args: [%Type{kind: :non_neg_integer}],
      result: %Type{kind: :integer},
      raw: :old
    }

    new = %Contract{
      module: Example,
      function: :fetch,
      arity: 1,
      args: [%Type{kind: :non_neg_integer}],
      result: %Type{kind: :non_neg_integer},
      raw: :new
    }

    assert Typespec.contract_compatible?(old, new)
    assert Typespec.Compatibility.compatible?(Typespec.contract_compatibility(old, new))

    changed_arg = %Contract{new | args: [%Type{kind: :integer}]}
    compatibility = Typespec.contract_compatibility(old, changed_arg)
    refute Typespec.Compatibility.compatible?(compatibility)
    assert Typespec.Compatibility.reason(compatibility) == :argument_shape_changed
  end

  test "encodes compatibility claims" do
    claim = Typespec.compatibility(%Type{kind: :integer}, %Type{kind: :non_neg_integer})

    assert {:ok, json} = Jason.encode!(claim) |> Jason.decode()
    assert json["compatible"] == true
  end
end
