defmodule Theoria.Kernel.EnvironmentCorpusTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel.EnvironmentCorpus
  alias Theoria.Kernel.Reference
  alias Theoria.Kernel.Reference.Normalize, as: ReferenceNormalize
  alias Theoria.Kernel.Reference.Replay
  alias Theoria.Normalize

  test "definition chain cases replay and normalize through production/reference paths" do
    for %EnvironmentCorpus.Case{} = corpus_case <- EnvironmentCorpus.cases() do
      assert Replay.run(corpus_case.env).failures == []

      for {_name, term} <- corpus_case.normalize do
        assert Normalize.normalize(corpus_case.env, term) ==
                 ReferenceNormalize.normalize(corpus_case.env, term)

        assert {:ok, _type} = Reference.infer(corpus_case.env, term)
      end
    end
  end
end
