defmodule Theoria.Inductive.GenerateTest do
  use ExUnit.Case, async: true

  alias Theoria.Env.Reduction
  alias Theoria.Inductive.Generate
  alias Theoria.Inductive.Spec
  alias Theoria.Library.{Bool, List, Nat}

  import Theoria.DSL

  test "generates Bool eliminators from constructors" do
    spec =
      :Bool
      |> Spec.new(Bool.type(), universe_params: [:u])
      |> Spec.constructor(true, Theoria.Term.const(:Bool))
      |> Spec.constructor(false, Theoria.Term.const(:Bool))

    assert [rec, ind] = Generate.bool_eliminators(spec)
    assert rec.name == :bool_rec
    assert rec.type == bool_rec_type()
    assert rec.reduction == bool_reduction()
    assert ind.name == :bool_ind
    assert ind.reduction == bool_reduction()
  end

  test "generates Nat eliminators from constructors" do
    spec = without_recursors(Nat.inductive_spec())

    assert [rec, ind] = Generate.nat_eliminators(spec)
    assert rec.name == :nat_rec
    assert rec.type == nat_rec_type()
    assert rec.reduction == nat_reduction()
    assert ind.name == :nat_ind
    assert ind.reduction == nat_reduction()
  end

  test "generates List eliminators from constructors" do
    spec = without_recursors(List.inductive_spec())

    assert [rec, ind] = Generate.list_eliminators(spec)
    assert rec.name == :list_rec
    assert rec.type == list_rec_type()
    assert rec.reduction == list_reduction()
    assert rec.reduction.constructors |> :lists.last() |> Map.fetch!(:recursive_positions) == [2]
    assert ind.name == :list_ind
    assert ind.reduction == list_reduction()
  end

  test "built-in libraries use generated eliminators" do
    assert Enum.map(Bool.inductive_spec().recursors, & &1.name) == [:bool_rec, :bool_ind]

    assert Nat.inductive_spec().recursors ==
             Generate.nat_eliminators(without_recursors(Nat.inductive_spec()))

    assert List.inductive_spec().recursors ==
             Generate.list_eliminators(without_recursors(List.inductive_spec()))
  end

  defp bool_rec_type do
    term do
      forall :a, sort(u) do
        a ~> (a ~> (bool() ~> a))
      end
    end
    |> elab!()
  end

  defp nat_rec_type do
    term do
      forall :a, sort(u) do
        a ~> (nat() ~> (a ~> a) ~> (nat() ~> a))
      end
    end
    |> elab!()
  end

  defp list_rec_type do
    u = Theoria.Level.param(:u)
    v = Theoria.Level.param(:v)
    list_a = Theoria.Syntax.app(Theoria.Syntax.const(:List, [u]), Theoria.Syntax.var(:a))

    term do
      forall :a, sort(^u) do
        forall :b, sort(^v) do
          b ~> (a ~> (^list_a ~> (b ~> b)) ~> (^list_a ~> b))
        end
      end
    end
    |> elab!()
  end

  defp bool_reduction do
    %Reduction.Recursor{
      inductive: :Bool,
      major_position: 3,
      constructors: [
        %{name: true, branch_position: 1, argument_positions: [], recursive_positions: []},
        %{name: false, branch_position: 2, argument_positions: [], recursive_positions: []}
      ]
    }
  end

  defp nat_reduction do
    %Reduction.Recursor{
      inductive: :Nat,
      major_position: 3,
      constructors: [
        %{name: :zero, branch_position: 1, argument_positions: [], recursive_positions: []},
        %{name: :succ, branch_position: 2, argument_positions: [0], recursive_positions: [0]}
      ]
    }
  end

  defp list_reduction do
    %Reduction.Recursor{
      inductive: :List,
      major_position: 4,
      constructors: [
        %{name: :list_nil, branch_position: 2, argument_positions: [], recursive_positions: []},
        %{
          name: :list_cons,
          branch_position: 3,
          argument_positions: [1, 2],
          recursive_positions: [2]
        }
      ]
    }
  end

  defp without_recursors(%Theoria.Inductive.Spec{} = spec) do
    %Theoria.Inductive.Spec{spec | recursors: []}
  end
end
