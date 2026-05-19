defmodule Theoria.Kernel.Differential do
  @moduledoc "Production/reference kernel differential checks."

  alias Theoria.Env
  alias Theoria.Equation.Extension
  alias Theoria.Equation.Matcher.Indexed.Realization, as: IndexedRealization
  alias Theoria.Equation.Realized
  alias Theoria.Kernel
  alias Theoria.Kernel.ArtifactReplay
  alias Theoria.Kernel.ArtifactReplay.Skip
  alias Theoria.Kernel.Corpus
  alias Theoria.Kernel.Differential.Options
  alias Theoria.Kernel.Differential.Timings
  alias Theoria.Kernel.EnvironmentCorpus
  alias Theoria.Kernel.EnvironmentCorpus.Report, as: EnvironmentReport
  alias Theoria.Kernel.GeneratedTerm
  alias Theoria.Kernel.GeneratedTerm.Failure, as: GeneratedTermFailure
  alias Theoria.Kernel.GeneratedTerm.Report, as: GeneratedTermReport
  alias Theoria.Kernel.Generator
  alias Theoria.Kernel.ProofStrategyReport
  alias Theoria.Kernel.Reference
  alias Theoria.Kernel.Reference.Normalize, as: ReferenceNormalize
  alias Theoria.Kernel.Reference.Replay
  alias Theoria.Kernel.TheoremModuleReport
  alias Theoria.Normalize
  alias Theoria.Term
  alias Theoria.Theorem
  alias Theoria.Validation.Corpus, as: ValidationCorpus
  alias Theoria.Validation.IndexedMatchers

  defmodule Report do
    @moduledoc "Summary of kernel differential checks."

    @enforce_keys [
      :infer_count,
      :check_count,
      :normalize_count,
      :defeq_count,
      :rejection_count,
      :generated_term_count,
      :generated_term_families,
      :generated_terms,
      :environment_count,
      :environment_replay_count,
      :environment_normalize_count,
      :environment_report,
      :invalid_environment_count,
      :theorem_count,
      :theorem_modules,
      :theorem_replay_count,
      :theorem_replay_skipped,
      :generated_artifact_count,
      :indexed_artifact_count,
      :proof_strategy_counts,
      :proof_strategies,
      :replay_count,
      :replay_skipped,
      :artifact_replay_count,
      :artifact_replay_skipped,
      :generated_artifact_replay_count,
      :indexed_artifact_replay_count,
      :artifact_replay_skips,
      :artifact_replay,
      :timings,
      :failures
    ]
    defstruct [
      :infer_count,
      :check_count,
      :normalize_count,
      :defeq_count,
      :rejection_count,
      :generated_term_count,
      :generated_term_families,
      :generated_terms,
      :environment_count,
      :environment_replay_count,
      :environment_normalize_count,
      :environment_report,
      :invalid_environment_count,
      :theorem_count,
      :theorem_modules,
      :theorem_replay_count,
      :theorem_replay_skipped,
      :generated_artifact_count,
      :indexed_artifact_count,
      :proof_strategy_counts,
      :proof_strategies,
      :replay_count,
      :replay_skipped,
      :artifact_replay_count,
      :artifact_replay_skipped,
      :generated_artifact_replay_count,
      :indexed_artifact_replay_count,
      :artifact_replay_skips,
      :artifact_replay,
      :timings,
      :failures
    ]

    @type failure :: {atom(), atom(), term(), term()} | Replay.Report.failure()
    @type t :: %__MODULE__{
            infer_count: non_neg_integer(),
            check_count: non_neg_integer(),
            normalize_count: non_neg_integer(),
            defeq_count: non_neg_integer(),
            rejection_count: non_neg_integer(),
            generated_term_count: non_neg_integer(),
            generated_term_families: %{atom() => non_neg_integer()},
            generated_terms: GeneratedTermReport.t(),
            environment_count: non_neg_integer(),
            environment_replay_count: non_neg_integer(),
            environment_normalize_count: non_neg_integer(),
            environment_report: EnvironmentReport.t(),
            invalid_environment_count: non_neg_integer(),
            theorem_count: non_neg_integer(),
            theorem_modules: [TheoremModuleReport.t()],
            theorem_replay_count: non_neg_integer(),
            theorem_replay_skipped: non_neg_integer(),
            generated_artifact_count: non_neg_integer(),
            indexed_artifact_count: non_neg_integer(),
            proof_strategy_counts: %{atom() => non_neg_integer()},
            proof_strategies: ProofStrategyReport.t(),
            replay_count: non_neg_integer(),
            replay_skipped: non_neg_integer(),
            artifact_replay_count: non_neg_integer(),
            artifact_replay_skipped: non_neg_integer(),
            generated_artifact_replay_count: non_neg_integer(),
            indexed_artifact_replay_count: non_neg_integer(),
            artifact_replay_skips: [ArtifactReplay.skip()],
            artifact_replay: ArtifactReplay.t(),
            timings: Timings.t(),
            failures: [failure()]
          }

    @spec ok?(t()) :: boolean()
    def ok?(%__MODULE__{failures: failures}), do: failures == []

    @spec failure_count(t()) :: non_neg_integer()
    def failure_count(%__MODULE__{failures: failures}), do: length(failures)

    @spec total_checks(t()) :: non_neg_integer()
    def total_checks(%__MODULE__{} = report) do
      report.infer_count + report.check_count + report.normalize_count + report.defeq_count +
        report.rejection_count + report.generated_term_count + report.environment_normalize_count +
        report.invalid_environment_count + report.theorem_count + report.generated_artifact_count +
        report.indexed_artifact_count
    end

    @spec total_replay_checks(t()) :: non_neg_integer()
    def total_replay_checks(%__MODULE__{} = report) do
      report.replay_count + report.environment_replay_count + report.theorem_replay_count +
        report.artifact_replay_count
    end
  end

  @doc "Compares production and reference inference for one term."
  @spec compare_infer(Env.t(), atom(), Term.t()) :: :ok | {:error, Report.failure()}
  def compare_infer(%Env{} = env, name, term) when is_atom(name) do
    compare(:infer, name, Kernel.infer(env, term), Reference.infer(env, term))
  end

  @doc "Compares production and reference checking for one term/type pair."
  @spec compare_check(Env.t(), atom(), Term.t(), Term.t()) :: :ok | {:error, Report.failure()}
  def compare_check(%Env{} = env, name, term, type) when is_atom(name) do
    compare(:check, name, Kernel.check(env, term, type), Reference.check(env, term, type))
  end

  @doc "Compares production and reference normalization for one term."
  @spec compare_normalize(Env.t(), atom(), Term.t()) :: :ok | {:error, Report.failure()}
  def compare_normalize(%Env{} = env, name, term) when is_atom(name) do
    compare(
      :normalize,
      name,
      Normalize.normalize(env, term),
      ReferenceNormalize.normalize(env, term)
    )
  end

  @doc "Compares production and reference definitional equality for one pair."
  @spec compare_defeq(Env.t(), atom(), Term.t(), Term.t()) :: :ok | {:error, Report.failure()}
  def compare_defeq(%Env{} = env, name, left, right) when is_atom(name) do
    compare(
      :defeq,
      name,
      Normalize.defeq?(env, left, right),
      ReferenceNormalize.defeq?(env, left, right)
    )
  end

  @doc "Compares production and reference checking for a theorem artifact."
  @spec compare_theorem(Env.t(), Theorem.t()) :: :ok | {:error, Report.failure()}
  def compare_theorem(%Env{} = env, %Theorem{} = theorem) do
    compare(
      :theorem,
      theorem.name,
      Kernel.check(env, theorem.proof, theorem.type),
      Reference.check(env, theorem.proof, theorem.type)
    )
  end

  @doc "Runs the default kernel differential corpus."
  @spec run(Env.t(), keyword() | Options.t()) :: Report.t()
  def run(%Env{} = env, opts \\ []) do
    {:ok, opts} = Options.parse(opts)
    total_start = monotonic_time()

    {infer_failures, infer_ms} =
      timed(fn -> failures(Corpus.infer_cases(), &compare_infer_case(env, &1)) end)

    {check_failures, check_ms} =
      timed(fn -> failures(Corpus.check_cases(), &compare_check_case(env, &1)) end)

    {rejection_failures, rejection_ms} =
      timed(fn ->
        failures(Corpus.infer_rejection_cases(), &compare_infer_case(env, &1)) ++
          failures(Corpus.check_rejection_cases(), &compare_check_case(env, &1))
      end)

    {normalize_failures, normalize_ms} =
      timed(fn -> failures(Corpus.normalize_cases(), &compare_normalize_case(env, &1)) end)

    {defeq_failures, defeq_ms} =
      timed(fn -> failures(Corpus.defeq_cases(), &compare_defeq_case(env, &1)) end)

    {{generated_terms, generated_term_failures}, generated_term_ms} =
      timed(fn -> generated_term_failures(opts) end)

    {environment_report, environment_ms} = timed(fn -> environment_report(opts) end)

    {{invalid_environment_count, invalid_environment_failures}, invalid_environment_ms} =
      timed(fn -> invalid_environment_failures(opts) end)

    {{theorem_count, theorem_modules, theorem_replay_count, theorem_replay_skipped,
      theorem_failures}, theorem_ms} =
      timed(fn -> theorem_failures(env) end)

    {{generated_artifact_count, generated_artifact_failures}, generated_artifact_ms} =
      timed(fn -> generated_artifact_failures(env) end)

    {{indexed_artifact_count, indexed_artifact_failures}, indexed_artifact_ms} =
      timed(fn -> indexed_artifact_failures(env) end)

    {replay_report, replay_ms} = timed(fn -> Replay.run(env) end)
    {artifact_replay, artifact_replay_ms} = timed(fn -> artifact_replay(env) end)

    proof_strategy_counts =
      proof_strategy_counts(generated_artifact_count, indexed_artifact_count)

    total_ms = Timings.elapsed_ms(total_start, monotonic_time())

    %Report{
      infer_count: length(Corpus.infer_cases()),
      check_count: length(Corpus.check_cases()),
      normalize_count: length(Corpus.normalize_cases()),
      defeq_count: length(Corpus.defeq_cases()),
      rejection_count:
        length(Corpus.infer_rejection_cases()) + length(Corpus.check_rejection_cases()),
      generated_term_count: generated_terms.total,
      generated_term_families: generated_terms.families,
      generated_terms: generated_terms,
      environment_count: environment_report.total,
      environment_replay_count: environment_report.replay_checks,
      environment_normalize_count: environment_report.normalize_checks,
      environment_report: environment_report,
      invalid_environment_count: invalid_environment_count,
      theorem_count: theorem_count,
      theorem_modules: theorem_modules,
      theorem_replay_count: theorem_replay_count,
      theorem_replay_skipped: theorem_replay_skipped,
      generated_artifact_count: generated_artifact_count,
      indexed_artifact_count: indexed_artifact_count,
      proof_strategy_counts: proof_strategy_counts,
      proof_strategies: ProofStrategyReport.new(proof_strategy_counts),
      replay_count: replay_report.checked,
      replay_skipped: replay_report.skipped,
      artifact_replay_count: ArtifactReplay.checked(artifact_replay),
      artifact_replay_skipped: ArtifactReplay.skipped_count(artifact_replay),
      generated_artifact_replay_count: artifact_replay.generated_checked,
      indexed_artifact_replay_count: artifact_replay.indexed_checked,
      artifact_replay_skips: artifact_replay.skipped,
      artifact_replay: artifact_replay,
      timings: %Timings{
        infer_ms: infer_ms,
        check_ms: check_ms,
        normalize_ms: normalize_ms,
        defeq_ms: defeq_ms,
        rejection_ms: rejection_ms,
        generated_term_ms: generated_term_ms,
        theorem_ms: theorem_ms + environment_ms + invalid_environment_ms,
        generated_artifact_ms: generated_artifact_ms,
        indexed_artifact_ms: indexed_artifact_ms,
        replay_ms: replay_ms,
        artifact_replay_ms: artifact_replay_ms,
        total_ms: total_ms
      },
      failures:
        infer_failures ++
          check_failures ++
          rejection_failures ++
          normalize_failures ++
          defeq_failures ++
          generated_term_failures ++
          environment_report.failures ++
          invalid_environment_failures ++
          theorem_failures ++
          generated_artifact_failures ++
          indexed_artifact_failures ++ replay_report.failures ++ artifact_replay.failures
    }
  end

  defp proof_strategy_counts(generated_artifact_count, indexed_artifact_count) do
    %{}
    |> put_positive(:refl, generated_artifact_count)
    |> put_positive(:recursor_iota_refl, indexed_artifact_count)
  end

  defp put_positive(counts, _strategy, 0), do: counts
  defp put_positive(counts, strategy, count), do: Map.put(counts, strategy, count)

  defp timed(function) do
    start = monotonic_time()
    result = function.()
    {result, Timings.elapsed_ms(start, monotonic_time())}
  end

  defp monotonic_time, do: System.monotonic_time()

  defp generated_term_failures(opts) do
    generator_opts = generated_term_options(opts)
    terms = Generator.small_terms(generator_opts)
    {GeneratedTermReport.new(terms, generator_opts), failures(terms, &compare_generated_term/1)}
  end

  defp generated_term_options(%Options{} = opts) do
    [size: opts.generated_size, max_terms: opts.generated_max_terms]
  end

  defp compare_generated_term(%GeneratedTerm{env: env, term: term, type: type} = generated) do
    with :ok <-
           compare_generated(
             :generated_infer,
             generated,
             Kernel.infer(env, term),
             Reference.infer(env, term)
           ),
         :ok <-
           compare_generated(
             :generated_check,
             generated,
             Kernel.check(env, term, type),
             Reference.check(env, term, type)
           ) do
      compare_generated(
        :generated_normalize,
        generated,
        Normalize.normalize(env, term),
        ReferenceNormalize.normalize(env, term)
      )
    end
  end

  defp compare_generated(kind, generated, production, reference) do
    if comparable(production) == comparable(reference) do
      :ok
    else
      {:error,
       {:generated_term, generated.name,
        GeneratedTermFailure.new(kind, generated, production, reference)}}
    end
  end

  defp environment_report(%Options{} = opts) do
    opts
    |> environment_options()
    |> EnvironmentCorpus.cases()
    |> Enum.map(&environment_case_report/1)
    |> EnvironmentReport.new()
  end

  defp environment_options(%Options{} = opts),
    do: [definition_chain_depth: opts.environment_depth]

  defp environment_case_report(%EnvironmentCorpus.Case{} = corpus_case) do
    replay_report = Replay.run(corpus_case.env)

    replay_failures =
      Enum.map(replay_report.failures, &{corpus_case.name, :environment_replay, &1})

    normalize_failures = environment_normalize_failures(corpus_case)

    %EnvironmentReport.Case{
      name: corpus_case.name,
      replay_checks: replay_report.checked,
      normalize_checks: length(corpus_case.normalize),
      failures: replay_failures ++ normalize_failures
    }
  end

  defp environment_normalize_failures(%EnvironmentCorpus.Case{} = corpus_case) do
    failures(corpus_case.normalize, fn {name, term} ->
      production = Normalize.normalize(corpus_case.env, term)
      reference = ReferenceNormalize.normalize(corpus_case.env, term)

      if comparable(production) == comparable(reference) do
        :ok
      else
        {:error, {:environment_normalize, {corpus_case.name, name}, production, reference}}
      end
    end)
  end

  defp invalid_environment_failures(%Options{} = opts) do
    cases = EnvironmentCorpus.invalid_cases(environment_options(opts))
    {length(cases), failures(cases, &compare_invalid_environment/1)}
  end

  defp compare_invalid_environment(%EnvironmentCorpus.InvalidCase{} = invalid_case) do
    case Kernel.validate_env(invalid_case.env) do
      {:error, %{reason: reason}} when reason == invalid_case.reason ->
        :ok

      {:error, reason} ->
        {:error, {:invalid_environment, invalid_case.name, reason, invalid_case.reason}}

      :ok ->
        {:error, {:invalid_environment, invalid_case.name, :accepted, invalid_case.reason}}
    end
  end

  defp artifact_replay(env) do
    with {:ok, generated_theorems} <- Extension.realize_all(env),
         generated_result <- replay_artifact_theorems(env, generated_theorems),
         {:ok, indexed_package} <- IndexedMatchers.check(env),
         {:ok, indexed_realized} <- IndexedRealization.realize_all(indexed_package),
         indexed_theorems = Enum.map(indexed_realized, &Realized.to_theorem/1),
         indexed_result <- replay_artifact_theorems(indexed_package.env, indexed_theorems) do
      merge_artifact_replay_results(generated_result, indexed_result)
    else
      {:error, reason} ->
        %ArtifactReplay{
          generated_checked: 0,
          indexed_checked: 0,
          skipped: [],
          failures: [{:artifact_replay, :generated, :failed, reason}]
        }
    end
  end

  defp replay_artifact_theorems(env, theorems) do
    {artifact_env, skipped} = install_artifact_theorems(env, theorems)
    report = Replay.run(artifact_env)
    base_count = length(Env.declarations(env))

    %ArtifactReplay{
      generated_checked: max(report.checked - base_count, 0),
      indexed_checked: 0,
      skipped: skipped,
      failures: report.failures
    }
  end

  defp merge_artifact_replay_results(generated, indexed) do
    %ArtifactReplay{
      generated_checked: generated.generated_checked,
      indexed_checked: indexed.generated_checked,
      skipped: generated.skipped ++ indexed.skipped,
      failures: generated.failures ++ indexed.failures
    }
  end

  defp install_artifact_theorems(env, theorems) do
    Enum.reduce(theorems, {env, []}, fn theorem, {env, skipped} ->
      case Theorem.add_to_env(env, theorem) do
        {:ok, env} ->
          {env, skipped}

        {:error, %Theoria.Error{} = error} ->
          {env, [artifact_skip(theorem, error) | skipped]}
      end
    end)
    |> then(fn {env, skipped} -> {env, Enum.reverse(skipped)} end)
  end

  defp artifact_skip(theorem, %Theoria.Error{reason: reason, details: details}) do
    Skip.new(theorem.name, reason, details)
  end

  defp indexed_artifact_failures(env) do
    with {:ok, package} <- IndexedMatchers.check(env),
         {:ok, realized} <- IndexedRealization.realize_all(package) do
      theorems = Enum.map(realized, &Realized.to_theorem/1)
      {length(theorems), failures(theorems, &compare_theorem(package.env, &1))}
    else
      {:error, reason} ->
        {0, [{:indexed_artifact, :vec_validation_match, :realization_failed, reason}]}
    end
  end

  defp generated_artifact_failures(env) do
    case Extension.realize_all(env) do
      {:ok, theorems} -> {length(theorems), failures(theorems, &compare_theorem(env, &1))}
      {:error, {name, error}} -> {0, [{:generated_artifact, name, :realization_failed, error}]}
    end
  end

  defp theorem_failures(env) do
    {count, replay_count, replay_skipped, modules, failures} =
      ValidationCorpus.builtin_theorem_modules()
      |> Enum.reduce({0, 0, 0, [], []}, fn module,
                                           {count, replay_count, replay_skipped, modules,
                                            failures} ->
        case Theorem.check_all(module, env) do
          {:ok, theorems} ->
            module_failures = failures(theorems, &compare_theorem(env, &1))

            {module_replay_count, module_replay_skipped, module_replay_failures} =
              replay_theorem_module(env, theorems)

            module_summary = %TheoremModuleReport{
              module: module,
              checks: length(theorems),
              replay_checks: module_replay_count,
              replay_skipped: module_replay_skipped,
              failures: List.flatten([module_failures, module_replay_failures])
            }

            {
              count + length(theorems),
              replay_count + module_replay_count,
              replay_skipped + module_replay_skipped,
              [module_summary | modules],
              [module_summary.failures | failures]
            }

          {:error, {name, error}} ->
            failure = {:theorem_module, name, :production_check_failed, error}

            module_summary = %TheoremModuleReport{
              module: module,
              checks: 0,
              replay_checks: 0,
              replay_skipped: 0,
              failures: [failure]
            }

            {count, replay_count, replay_skipped, [module_summary | modules],
             [[failure] | failures]}
        end
      end)

    {count, Enum.reverse(modules), replay_count, replay_skipped,
     failures |> Enum.reverse() |> List.flatten()}
  end

  defp replay_theorem_module(env, theorems) do
    {theorem_env, skipped} = install_artifact_theorems(env, theorems)
    report = Replay.run(theorem_env)
    base_count = length(Env.declarations(env))
    {max(report.checked - base_count, 0), length(skipped) + report.skipped, report.failures}
  end

  defp failures(cases, callback) do
    Enum.flat_map(cases, fn test_case ->
      case callback.(test_case) do
        :ok -> []
        {:error, failure} -> [failure]
      end
    end)
  end

  defp compare_infer_case(env, {name, term}), do: compare_infer(env, name, term)
  defp compare_check_case(env, {name, term, type}), do: compare_check(env, name, term, type)
  defp compare_normalize_case(env, {name, term}), do: compare_normalize(env, name, term)
  defp compare_defeq_case(env, {name, left, right}), do: compare_defeq(env, name, left, right)

  defp compare(kind, name, production, reference) do
    if comparable(production) == comparable(reference) do
      :ok
    else
      {:error, {kind, name, production, reference}}
    end
  end

  defp comparable({:ok, value}), do: {:ok, value}
  defp comparable(:ok), do: :ok
  defp comparable({:error, %{reason: reason}}), do: {:error, reason}
  defp comparable(true), do: true
  defp comparable(false), do: false
end
