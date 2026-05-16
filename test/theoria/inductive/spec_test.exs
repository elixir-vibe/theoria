defmodule Theoria.Inductive.SpecTest do
  use ExUnit.Case, async: true

  alias Theoria.Env.Reduction
  alias Theoria.Inductive
  alias Theoria.Inductive.{Constructor, Recursor, Spec}
  alias Theoria.Level

  import Theoria.Term

  test "validates a minimal inductive spec" do
    spec = %Spec{
      name: :Unit,
      type: sort(1),
      constructors: [%Constructor{name: :unit, type: const(:Unit)}]
    }

    assert Inductive.validate(spec) == :ok
  end

  test "rejects duplicate declaration names" do
    spec = %Spec{
      name: :Nat,
      type: sort(1),
      constructors: [
        %Constructor{name: :zero, type: const(:Nat)},
        %Constructor{name: :zero, type: const(:Nat)}
      ]
    }

    assert {:error, error} = Inductive.validate(spec)
    assert error.reason == :invalid_inductive
    assert Keyword.fetch!(error.details, :problem) == :duplicate_declaration
  end

  test "rejects constructor results that do not target the inductive" do
    spec = %Spec{
      name: :Nat,
      type: sort(1),
      constructors: [%Constructor{name: :bad, type: const(:Bool)}]
    }

    assert {:error, error} = Inductive.validate(spec)
    assert Keyword.fetch!(error.details, :problem) == :constructor_target_mismatch
  end

  test "accepts positive recursive constructor occurrences" do
    spec = %Spec{
      name: :Nat,
      type: sort(1),
      constructors: [
        %Constructor{name: :zero, type: const(:Nat)},
        %Constructor{name: :succ, type: arrow(const(:Nat), const(:Nat))}
      ]
    }

    assert Inductive.validate(spec) == :ok
  end

  test "accepts constructors without recursive occurrences" do
    spec = %Spec{
      name: :Box,
      type: sort(1),
      constructors: [%Constructor{name: :box, type: arrow(const(:Nat), const(:Box))}]
    }

    assert Inductive.validate(spec) == :ok
  end

  test "rejects negative recursive constructor occurrences" do
    spec = %Spec{
      name: :Bad,
      type: sort(1),
      constructors: [
        %Constructor{name: :bad, type: arrow(arrow(const(:Bad), const(:Nat)), const(:Bad))}
      ]
    }

    assert {:error, error} = Inductive.validate(spec)
    assert Keyword.fetch!(error.details, :problem) == :non_positive_constructor
    assert Keyword.fetch!(error.details, :constructor) == :bad
  end

  test "accepts recursive occurrences in nested positive result positions" do
    spec = %Spec{
      name: :Bad,
      type: sort(1),
      constructors: [
        %Constructor{name: :bad, type: arrow(arrow(const(:Nat), const(:Bad)), const(:Bad))}
      ]
    }

    assert Inductive.validate(spec) == :ok
  end

  test "rejects unknown universe parameters" do
    spec = %Spec{
      name: :Box,
      type: sort(Level.param(:u)),
      constructors: [%Constructor{name: :box, type: const(:Box, [Level.param(:u)])}]
    }

    assert {:error, error} = Inductive.validate(spec)
    assert Keyword.fetch!(error.details, :problem) == :unknown_universe_parameter
    assert Keyword.fetch!(error.details, :params) == [:u]
  end

  test "rejects invalid recursor reduction metadata" do
    spec = %Spec{
      name: :Nat,
      type: sort(1),
      constructors: [%Constructor{name: :zero, type: const(:Nat)}],
      recursors: [%Recursor{name: :nat_rec, type: const(:Nat), reduction: :bad}]
    }

    assert {:error, error} = Inductive.validate(spec)
    assert Keyword.fetch!(error.details, :problem) == :invalid_reduction
  end

  test "accepts recursor reduction metadata" do
    spec = %Spec{
      name: :Nat,
      type: sort(1),
      constructors: [%Constructor{name: :zero, type: const(:Nat)}],
      recursors: [%Recursor{name: :nat_rec, type: const(:Nat), reduction: %Reduction.Iota{}}]
    }

    assert Inductive.validate(spec) == :ok
  end
end
