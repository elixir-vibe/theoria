defmodule Theoria.TypespecTest do
  use ExUnit.Case, async: true

  alias Theoria.Typespec
  alias Theoria.Typespec.Contract
  alias Theoria.Typespec.Report
  alias Theoria.Typespec.Type

  test "fetches normalized contracts for a loaded module" do
    assert {:ok, contracts} = Typespec.fetch(Theoria.Obligation)
    assert Enum.any?(contracts, &(Contract.mfa(&1) == {Theoria.Obligation, :new, 3}))
  end

  test "normalizes common contract fragments" do
    assert {:ok, [contract]} = Typespec.from_mfa({Theoria.Obligation, :new, 3})

    assert [kind_type, goal_type, opts_type] = contract.args
    assert kind_type.kind == :atom
    assert goal_type.kind == :remote
    assert goal_type.module == Theoria.Term
    assert goal_type.name == :t
    assert opts_type.kind == :remote
    assert contract.result.kind == :user
    assert Contract.format(contract) =~ "Theoria.Obligation.new(atom()"
    refute Contract.unsupported?(contract)
  end

  test "normalizes lists and struct references" do
    assert {:ok, [contract]} = Typespec.from_mfa({Theoria.Certificate.Report, :new, 1})

    assert [list_type] = contract.args
    assert list_type.kind == :list
    assert [%Type{kind: :struct, module: Theoria.Certificate}] = list_type.args
    assert Type.format(list_type) == "[%Theoria.Certificate{}]"
  end

  test "normalizes String.t returns and literal unions" do
    assert {:ok, [contract]} = Typespec.from_mfa({String, :valid?, 2})

    assert [_string_type, options] = contract.args
    assert options.kind == :union
    assert Enum.any?(options.args, &(&1.kind == :literal and &1.value == :default))
    assert contract.result.kind == :boolean
  end

  test "reports module contract counts" do
    assert {:ok, report} = Typespec.report(Theoria.Certificate.Report)

    assert Report.total(report) > 0
    assert Report.unsupported(report) == 0
    assert length(Report.contracts(report)) == Report.total(report)

    assert {:ok, json} = Jason.encode!(report) |> Jason.decode()
    assert json["total"] == Report.total(report)
  end

  test "returns an error for unknown specs in a loaded module" do
    assert {:error, {:unknown_typespec, {Theoria.Obligation, :missing, 1}}} =
             Typespec.from_mfa({Theoria.Obligation, :missing, 1})
  end
end
