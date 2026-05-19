defmodule Theoria.Kernel.Differential do
  @moduledoc "Production/reference kernel differential checks."

  alias Theoria.Env
  alias Theoria.Equation.Extension
  alias Theoria.Kernel
  alias Theoria.Kernel.Corpus
  alias Theoria.Kernel.Reference
  alias Theoria.Kernel.Reference.Normalize, as: ReferenceNormalize
  alias Theoria.Normalize
  alias Theoria.Term
  alias Theoria.Theorem
  alias Theoria.Validation.Corpus, as: ValidationCorpus

  defmodule Report do
    @moduledoc "Summary of kernel differential checks."

    @enforce_keys [
      :infer_count,
      :check_count,
      :normalize_count,
      :defeq_count,
      :rejection_count,
      :theorem_count,
      :generated_artifact_count,
      :failures
    ]
    defstruct [
      :infer_count,
      :check_count,
      :normalize_count,
      :defeq_count,
      :rejection_count,
      :theorem_count,
      :generated_artifact_count,
      :failures
    ]

    @type failure :: {atom(), atom(), term(), term()}
    @type t :: %__MODULE__{
            infer_count: non_neg_integer(),
            check_count: non_neg_integer(),
            normalize_count: non_neg_integer(),
            defeq_count: non_neg_integer(),
            rejection_count: non_neg_integer(),
            theorem_count: non_neg_integer(),
            generated_artifact_count: non_neg_integer(),
            failures: [failure()]
          }

    @spec ok?(t()) :: boolean()
    def ok?(%__MODULE__{failures: failures}), do: failures == []
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
  @spec run(Env.t()) :: Report.t()
  def run(%Env{} = env) do
    infer_failures = failures(Corpus.infer_cases(), &compare_infer_case(env, &1))
    check_failures = failures(Corpus.check_cases(), &compare_check_case(env, &1))

    rejection_failures =
      failures(Corpus.infer_rejection_cases(), &compare_infer_case(env, &1)) ++
        failures(Corpus.check_rejection_cases(), &compare_check_case(env, &1))

    normalize_failures = failures(Corpus.normalize_cases(), &compare_normalize_case(env, &1))
    defeq_failures = failures(Corpus.defeq_cases(), &compare_defeq_case(env, &1))
    {theorem_count, theorem_failures} = theorem_failures(env)
    {generated_artifact_count, generated_artifact_failures} = generated_artifact_failures(env)

    %Report{
      infer_count: length(Corpus.infer_cases()),
      check_count: length(Corpus.check_cases()),
      normalize_count: length(Corpus.normalize_cases()),
      defeq_count: length(Corpus.defeq_cases()),
      rejection_count:
        length(Corpus.infer_rejection_cases()) + length(Corpus.check_rejection_cases()),
      theorem_count: theorem_count,
      generated_artifact_count: generated_artifact_count,
      failures:
        infer_failures ++
          check_failures ++
          rejection_failures ++
          normalize_failures ++
          defeq_failures ++ theorem_failures ++ generated_artifact_failures
    }
  end

  defp generated_artifact_failures(env) do
    case Extension.realize_all(env) do
      {:ok, theorems} -> {length(theorems), failures(theorems, &compare_theorem(env, &1))}
      {:error, {name, error}} -> {0, [{:generated_artifact, name, :realization_failed, error}]}
    end
  end

  defp theorem_failures(env) do
    {count, failures} =
      ValidationCorpus.builtin_theorem_modules()
      |> Enum.reduce({0, []}, fn module, {count, failures} ->
        case Theorem.check_all(module, env) do
          {:ok, theorems} ->
            module_failures = failures(theorems, &compare_theorem(env, &1))
            {count + length(theorems), [module_failures | failures]}

          {:error, {name, error}} ->
            failure = {:theorem_module, name, :production_check_failed, error}
            {count, [[failure] | failures]}
        end
      end)

    {count, failures |> Enum.reverse() |> List.flatten()}
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
