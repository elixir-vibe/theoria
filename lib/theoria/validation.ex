defmodule Theoria.Validation do
  @moduledoc "Runs Theoria-owned validation corpora."

  alias Theoria.Equation.{Eqns, Info, Lemma, MatcherEqns, MatcherEquation}
  alias Theoria.Prelude
  alias Theoria.Theorem
  alias Theoria.Validation.{Checkable, Corpus, Report}

  @doc "Checks theorem modules, definitional equalities, and inductive specs."
  @spec check(Corpus.t()) :: {:ok, Report.t()} | {:error, term()}
  def check(%Corpus{} = corpus) do
    with {:ok, env} <- Prelude.env(),
         :ok <- check_all(env, corpus.theorem_checks),
         :ok <- check_all(env, corpus.defeq_checks),
         :ok <- check_all(env, corpus.inductive_checks),
         :ok <- check_equation_metadata(env),
         {:ok, _env, generated_equations} <- Eqns.install_all(env),
         {:ok, matcher_equation_count} <- check_matcher_equations(env),
         {:ok, theorem_count, axioms} <- theorem_summary(env, corpus.theorem_modules) do
      {:ok,
       %Report{
         categories: corpus.categories,
         theorem_count: theorem_count,
         defeq_count: length(corpus.defeq_checks),
         inductive_count: length(corpus.inductive_checks),
         equations: Info.all(env),
         generated_equation_count: length(generated_equations),
         matcher_equation_count: matcher_equation_count,
         axioms: axioms
       }}
    end
  end

  defp check_all(env, checks) do
    Enum.reduce_while(checks, :ok, fn check, :ok ->
      case Checkable.check(check, env) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {check, reason}}}
      end
    end)
  end

  defp check_equation_metadata(env) do
    env
    |> Info.all()
    |> Enum.reduce_while(:ok, fn info, :ok ->
      case validate_equation_info(env, info) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {:equation_metadata, info.name, reason}}}
      end
    end)
  end

  defp validate_equation_info(env, info) do
    case validate_schema_rec_arg(info) do
      :ok -> validate_equation_matcher_metadata(env, info)
      {:error, _reason} = error -> error
    end
  end

  defp validate_equation_matcher_metadata(env, info) do
    with :ok <- validate_matcher_discriminants(info),
         :ok <- validate_fixed_params(info) do
      validate_matcher_sources(env, info)
    end
  end

  defp validate_schema_rec_arg(%Info{schema: nil}), do: :ok

  defp validate_schema_rec_arg(%Info{} = info) do
    if info.rec_arg_pos == info.schema.recursive_argument do
      :ok
    else
      {:error, {:rec_arg_mismatch, info.rec_arg_pos, info.schema.recursive_argument}}
    end
  end

  defp validate_matcher_discriminants(%Info{matcher: nil}), do: :ok

  defp validate_matcher_discriminants(%Info{} = info) do
    if info.matcher.num_discriminants == length(info.matcher.discriminants) do
      :ok
    else
      {:error, {:discriminant_count_mismatch, info.matcher.num_discriminants}}
    end
  end

  defp validate_fixed_params(%Info{schema: nil}), do: :ok

  defp validate_fixed_params(%Info{} = info) do
    parameter_count = length(info.schema.parameter_binders)

    case Enum.find(info.fixed_params.positions, &(&1 < 0 or &1 >= parameter_count)) do
      nil -> :ok
      position -> {:error, {:invalid_fixed_param, position, parameter_count}}
    end
  end

  defp validate_matcher_sources(env, info) do
    info
    |> MatcherEqns.generated()
    |> Enum.reduce_while(:ok, fn equation, :ok ->
      case Eqns.source(env, equation.name) do
        {:ok, source} when source == info.name -> {:cont, :ok}
        other -> {:halt, {:error, {:invalid_matcher_source, equation.name, other}}}
      end
    end)
  end

  defp check_matcher_equations(env) do
    env
    |> MatcherEqns.all()
    |> Enum.reduce_while({:ok, 0}, fn %MatcherEquation{} = equation, {:ok, count} ->
      case Lemma.to_theorem(env, MatcherEquation.to_lemma(equation)) do
        {:ok, _theorem} -> {:cont, {:ok, count + 1}}
        {:error, error} -> {:halt, {:error, {:matcher_equation, equation.name, error}}}
      end
    end)
  end

  defp theorem_summary(env, modules) do
    Enum.reduce_while(modules, {:ok, 0, MapSet.new()}, fn module, {:ok, count, axioms} ->
      case Theorem.check_all(module, env) do
        {:ok, theorems} ->
          {:cont,
           {:ok, count + length(theorems), MapSet.union(axioms, module_axioms(theorems, env))}}

        {:error, error} ->
          {:halt, {:error, {:theorem, module, error}}}
      end
    end)
  end

  defp module_axioms(theorems, env) do
    Enum.reduce(theorems, MapSet.new(), fn theorem, axioms ->
      case Theorem.axioms(env, theorem) do
        {:ok, theorem_axioms} -> MapSet.union(axioms, theorem_axioms)
      end
    end)
  end
end
