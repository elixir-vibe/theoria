defmodule Theoria.Validation do
  @moduledoc "Runs Theoria-owned validation corpora."

  alias Theoria.Equation.Info, as: EquationInfo
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
         {:ok, theorem_count, axioms} <- theorem_summary(env, corpus.theorem_modules) do
      {:ok,
       %Report{
         categories: corpus.categories,
         theorem_count: theorem_count,
         defeq_count: length(corpus.defeq_checks),
         inductive_count: length(corpus.inductive_checks),
         equation_count: length(EquationInfo.all(env)),
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
