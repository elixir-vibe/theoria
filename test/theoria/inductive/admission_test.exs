defmodule Theoria.Inductive.AdmissionTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Inductive
  alias Theoria.Inductive.Admission
  alias Theoria.Inductive.Index
  alias Theoria.Inductive.Spec
  alias Theoria.Level
  alias Theoria.Library.Nat
  alias Theoria.Term

  import Theoria.DSL

  test "tracks and validates declaration parameter count" do
    spec = Spec.new(:Box, Term.sort(1)) |> Spec.parameter(:a, Term.sort(1))
    spec = %Spec{spec | num_params: 0}

    assert {:error, error} = Inductive.validate(spec)
    assert Keyword.fetch!(error.details, :problem) == :parameter_count_mismatch
  end

  test "rejects constructor fields in a larger universe than the inductive result" do
    spec = %Spec{
      name: :Small,
      type: Term.sort(1),
      constructors: [
        %Theoria.Inductive.Constructor{
          name: :small,
          type: Term.arrow(Term.sort(2), Term.const(:Small))
        }
      ]
    }

    assert {:error, error} = Admission.check(Env.new(), spec)
    assert Keyword.fetch!(error.details, :problem) == :constructor_field_universe_too_large
  end

  test "allows larger constructor fields for Prop-valued inductives" do
    spec = %Spec{
      name: :Witness,
      type: Term.sort(0),
      constructors: [
        %Theoria.Inductive.Constructor{
          name: :witness,
          type: Term.arrow(Term.sort(2), Term.const(:Witness))
        }
      ]
    }

    assert Admission.check(Env.new(), spec) == :ok
  end

  test "rejects recursive occurrences in constructor index arguments" do
    spec = %Spec{
      name: :Bad,
      type: Term.arrow(Term.const(:Nat), Term.sort(1)),
      indices: [%Index{name: :n, type: Term.const(:Nat)}],
      constructors: [
        %Theoria.Inductive.Constructor{
          name: :bad,
          type: Term.app(Term.const(:Bad), Term.const(:Bad))
        }
      ]
    }

    assert {:error, error} = Inductive.validate(spec)
    assert Keyword.fetch!(error.details, :problem) == :constructor_index_recursive_occurrence
  end

  test "plans valid Vec-like specs with lean-style metadata" do
    {:ok, env} = Nat.env()
    assert {:ok, declarations} = Admission.plan(env, vec_spec())

    assert [:Vec, :vec_nil, :vec_cons] = Enum.map(declarations, & &1.name)
    assert [:inductive, :constructor, :constructor] = Enum.map(declarations, & &1.kind)
    assert match?(%Theoria.Env.Inductive{}, hd(declarations).metadata)
  end

  defp vec_spec do
    u = Level.param(:u)

    :Vec
    |> Spec.new(vec_type(u), universe_params: [:u])
    |> Spec.parameter(:a, term(do: sort(^u)) |> elab!())
    |> Spec.index(:n, term(do: nat()) |> elab!())
    |> Spec.constructor(:vec_nil, vec_nil_type(u))
    |> Spec.constructor(:vec_cons, vec_cons_type(u))
  end

  defp vec_type(u) do
    term do
      forall :a, sort(^u) do
        nat() ~> sort(^u)
      end
    end
    |> elab!()
  end

  defp vec_nil_type(u) do
    term do
      forall :a, sort(^u) do
        app(app(const(:Vec, [^u]), a), zero)
      end
    end
    |> elab!()
  end

  defp vec_cons_type(u) do
    term do
      forall :a, sort(^u) do
        a
        ~> forall :n, nat() do
          app(app(const(:Vec, [^u]), a), n)
          ~> app(app(const(:Vec, [^u]), a), app(succ, n))
        end
      end
    end
    |> elab!()
  end
end
