defmodule Theoria.CorpusSummaryTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel.Corpus, as: KernelCorpus
  alias Theoria.Validation.Corpus, as: ValidationCorpus

  test "kernel corpus summary exposes curated counts" do
    summary = KernelCorpus.summary()

    assert summary.infer == length(KernelCorpus.infer_cases())
    assert summary.check == length(KernelCorpus.check_cases())
    assert summary.normalize == length(KernelCorpus.normalize_cases())
    assert summary.defeq == length(KernelCorpus.defeq_cases())

    assert summary.rejection ==
             length(KernelCorpus.infer_rejection_cases()) +
               length(KernelCorpus.check_rejection_cases())
  end

  test "validation corpus summary exposes workflow counts" do
    summary = ValidationCorpus.summary()

    assert summary.categories == ValidationCorpus.valid_categories()
    assert summary.theorem_modules == length(ValidationCorpus.builtin_theorem_modules())
    assert summary.theorem_checks > 0
    assert summary.defeq_checks > 0
    assert summary.inductive_checks > 0
  end
end
