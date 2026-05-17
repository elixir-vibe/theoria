defmodule Theoria.Validation.CorpusTest do
  use ExUnit.Case, async: true

  alias Theoria.Prelude
  alias Theoria.Validation.Corpus
  alias Theoria.Validation.DefeqCheck

  test "validation corpus is Theoria-owned and locally checkable" do
    {:ok, env} = Prelude.env()
    corpus = Corpus.build()

    assert Theoria.Library.Vec.Theorems in corpus.theorem_modules
    assert Enum.any?(corpus.defeq_checks, &(&1.name == "small_vec_ind_singleton"))
    assert Enum.all?(corpus.defeq_checks, &(DefeqCheck.check(env, &1) == :ok))
  end

  test "filters validation categories" do
    corpus = Corpus.build(only: [:vec])

    assert corpus.theorem_modules == [Theoria.Library.Vec.Theorems]
    assert Enum.all?(corpus.defeq_checks, &(&1.category == :vec))
  end
end
