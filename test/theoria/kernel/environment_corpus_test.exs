defmodule Theoria.Kernel.EnvironmentCorpusTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Kernel.EnvironmentCorpus
  alias Theoria.Kernel.Reference
  alias Theoria.Kernel.Reference.Normalize, as: ReferenceNormalize
  alias Theoria.Kernel.Reference.Replay
  alias Theoria.Normalize

  test "definition chain cases replay and normalize through production/reference paths" do
    cases = EnvironmentCorpus.cases()

    assert Enum.map(cases, & &1.name) == [
             :definition_chain,
             :let_chain,
             :theorem_chain,
             :universe_polymorphic_chain
           ]

    for %EnvironmentCorpus.Case{} = corpus_case <- cases do
      assert Replay.run(corpus_case.env).failures == []

      for {_name, term} <- corpus_case.normalize do
        assert Normalize.normalize(corpus_case.env, term) ==
                 ReferenceNormalize.normalize(corpus_case.env, term)

        assert {:ok, _type} = Reference.infer(corpus_case.env, term)
      end
    end
  end

  test "invalid cases are rejected by native environment validation" do
    cases = EnvironmentCorpus.invalid_cases()

    assert Enum.map(cases, & &1.name) == [
             :missing_declaration_index,
             :untracked_declaration,
             :duplicate_declaration_index,
             :definition_value_type_mismatch,
             :theorem_proof_type_mismatch,
             :unknown_constant_dependency
           ]

    for %EnvironmentCorpus.InvalidCase{} = invalid_case <- cases do
      assert {:error, %{reason: reason}} = Kernel.validate_env(invalid_case.env)
      assert reason == invalid_case.reason
    end
  end
end
