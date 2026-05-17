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
    assert rec.reduction == %Reduction.Iota{}
    assert ind.name == :bool_ind
    assert ind.type == bool_ind_type()
    assert ind.reduction == %Reduction.Iota{}
  end

  test "generates Nat eliminators from constructors" do
    spec = without_recursors(Nat.inductive_spec())

    assert [rec, ind] = Generate.nat_eliminators(spec)
    assert rec.name == :nat_rec
    assert rec.type == nat_rec_type()
    assert rec.reduction == %Reduction.Iota{}
    assert ind.name == :nat_ind
    assert ind.type == nat_ind_type()
    assert ind.reduction == %Reduction.Iota{}
  end

  test "generates List eliminators from constructors" do
    spec = without_recursors(List.inductive_spec())

    assert [rec, ind] = Generate.list_eliminators(spec)
    assert rec.name == :list_rec
    assert rec.type == list_rec_type()
    assert rec.reduction == %Reduction.Iota{}
    assert ind.name == :list_ind
    assert ind.type == list_ind_type()
    assert ind.reduction == %Reduction.Iota{}
  end

  test "generic eliminators match named generator wrappers" do
    assert {:ok, bool_eliminators} =
             Generate.eliminators(without_recursors(Bool.inductive_spec()))

    assert bool_eliminators == Generate.bool_eliminators(without_recursors(Bool.inductive_spec()))

    assert {:ok, nat_eliminators} = Generate.eliminators(without_recursors(Nat.inductive_spec()))
    assert nat_eliminators == Generate.nat_eliminators(without_recursors(Nat.inductive_spec()))

    assert {:ok, list_eliminators} =
             Generate.eliminators(without_recursors(List.inductive_spec()))

    assert list_eliminators == Generate.list_eliminators(without_recursors(List.inductive_spec()))
  end

  test "built-in libraries use generic generated eliminators" do
    assert Enum.map(Bool.inductive_spec().recursors, & &1.name) == [:bool_rec, :bool_ind]

    assert Nat.inductive_spec().recursors ==
             Generate.eliminators!(without_recursors(Nat.inductive_spec()))

    assert List.inductive_spec().recursors ==
             Generate.eliminators!(without_recursors(List.inductive_spec()))
  end

  test "reports eliminator generation capabilities" do
    assert %{supported?: true, simple?: true, indexed?: false, reason: nil, shape: :list_like} =
             Generate.capabilities(without_recursors(List.inductive_spec()))

    assert Generate.supported?(without_recursors(Nat.inductive_spec()))
    refute Generate.supported?(vec_spec())
    assert Generate.unsupported_reason(vec_spec()) == :indexed_eliminators_unsupported
  end

  test "generates opaque indexed eliminators" do
    assert {:ok,
            [
              %Theoria.Inductive.Recursor{
                name: :vec_ind,
                reduction: %Theoria.Env.Reduction.Iota{},
                type: type
              }
            ]} = Generate.indexed_eliminators(vec_spec())

    assert Theoria.Term.well_scoped?(type)
  end

  test "generic eliminators reject unsupported specs" do
    assert {:error, indexed_error} = Generate.eliminators(vec_spec())
    assert indexed_error.reason == :invalid_inductive
    assert Keyword.fetch!(indexed_error.details, :problem) == :indexed_eliminators_unsupported

    assert {:error, unknown_error} = Generate.eliminators(unit_spec())
    assert unknown_error.reason == :invalid_inductive
    assert Keyword.fetch!(unknown_error.details, :problem) == :unknown_shape
  end

  defp bool_rec_type do
    term do
      forall :a, sort(u) do
        a ~> (a ~> (bool() ~> a))
      end
    end
    |> elab!()
  end

  defp bool_ind_type do
    term do
      forall :motive, bool() ~> sort(u) do
        app(motive, bool_true())
        ~> (app(motive, bool_false())
            ~> forall :b, bool() do
              app(motive, b)
            end)
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

  defp nat_ind_type do
    term do
      forall :motive, nat() ~> sort(u) do
        app(motive, zero)
        ~> (forall :arg0, nat() do
              app(motive, arg0) ~> app(motive, app(succ, arg0))
            end
            ~> forall :n, nat() do
              app(motive, n)
            end)
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

  defp list_ind_type do
    u = Theoria.Level.param(:u)
    v = Theoria.Level.param(:v)
    list_a = Theoria.Syntax.app(Theoria.Syntax.const(:List, [u]), Theoria.Syntax.var(:a))
    nil_a = Theoria.Syntax.app(Theoria.Syntax.const(:list_nil, [u]), Theoria.Syntax.var(:a))

    cons_a_arg0_arg1 =
      Theoria.Syntax.const(:list_cons, [u])
      |> Theoria.Syntax.app(Theoria.Syntax.var(:a))
      |> Theoria.Syntax.app(Theoria.Syntax.var(:arg0))
      |> Theoria.Syntax.app(Theoria.Syntax.var(:arg1))

    term do
      forall :a, sort(^u) do
        forall :motive, ^list_a ~> sort(^v) do
          app(motive, ^nil_a)
          ~> (forall :arg0, a do
                forall :arg1, ^list_a do
                  app(motive, arg1) ~> app(motive, ^cons_a_arg0_arg1)
                end
              end
              ~> forall :xs, ^list_a do
                app(motive, xs)
              end)
        end
      end
    end
    |> elab!()
  end

  defp vec_spec do
    u = Theoria.Level.param(:u)

    :Vec
    |> Spec.new(vec_type(u), universe_params: [:u])
    |> Spec.parameter(:a, term(do: sort(^u)) |> elab!())
    |> Spec.index(:n, term(do: nat()) |> elab!())
    |> Spec.constructor(:vec_nil, vec_nil_type(u))
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

  defp unit_spec do
    :Unit
    |> Spec.new(term(do: sort(1)) |> elab!())
    |> Spec.constructor(:unit, term(do: const(:Unit)) |> elab!())
  end

  defp without_recursors(%Theoria.Inductive.Spec{} = spec) do
    %Theoria.Inductive.Spec{spec | recursors: []}
  end
end
