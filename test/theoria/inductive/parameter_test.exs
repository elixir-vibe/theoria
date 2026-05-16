defmodule Theoria.Inductive.ParameterTest do
  use ExUnit.Case, async: true

  alias Theoria.Inductive
  alias Theoria.Inductive.{Constructor, Parameter, Spec}
  alias Theoria.Library.List

  import Theoria.Term

  test "list spec declares its element parameter" do
    assert [%Parameter{name: :a, type: type}] = List.inductive_spec().parameters
    assert type == sort(Theoria.Level.param(:u))
  end

  test "rejects constructor results that do not preserve family parameters" do
    spec = %Spec{
      name: :BadList,
      type: forall(:a, sort(1), sort(1)),
      universe_params: [:u],
      parameters: [%Parameter{name: :a, type: sort(1)}],
      constructors: [
        %Constructor{name: :bad_nil, type: forall(:a, sort(1), app(const(:BadList), sort(0)))}
      ]
    }

    assert {:error, error} = Inductive.validate(spec)
    assert error.reason == :invalid_inductive
    assert Keyword.fetch!(error.details, :problem) == :constructor_parameter_mismatch
    assert Keyword.fetch!(error.details, :constructor) == :bad_nil
  end

  test "reports inductive declaration plans" do
    assert {:ok, report} = Inductive.report(List.inductive_spec())

    assert report.name == :List
    assert report.shape == :list_like
    assert report.universe_params == [:u, :v]
    assert report.declarations == [:List, :list_nil, :list_cons, :list_rec, :list_ind]

    assert inspect(report) ==
             "#Theoria<inductive List : list_like, params: u, v, decls: List, list_nil, list_cons, list_rec, list_ind>"
  end
end
