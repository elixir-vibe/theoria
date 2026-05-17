defmodule Theoria.Validation do
  @moduledoc "Runs Theoria-owned validation corpora."

  alias Theoria.Prelude
  alias Theoria.Theorem
  alias Theoria.Validation.{Corpus, DefeqCheck, InductiveCheck}

  @type result :: %{
          theorem_count: non_neg_integer(),
          defeq_count: non_neg_integer(),
          inductive_count: non_neg_integer()
        }

  @doc "Checks theorem modules, definitional equalities, and inductive specs."
  @spec check(Corpus.t()) :: {:ok, result()} | {:error, term()}
  def check(%Corpus{} = corpus) do
    with {:ok, env} <- Prelude.env(),
         {:ok, theorem_count} <- check_theorems(env, corpus.theorem_modules),
         :ok <- check_defeqs(env, corpus.defeq_checks),
         :ok <- check_inductives(env, corpus.inductive_checks) do
      {:ok,
       %{
         theorem_count: theorem_count,
         defeq_count: length(corpus.defeq_checks),
         inductive_count: length(corpus.inductive_checks)
       }}
    end
  end

  defp check_theorems(env, modules) do
    Enum.reduce_while(modules, {:ok, 0}, fn module, {:ok, count} ->
      case Theorem.check_all(module, env) do
        {:ok, theorems} -> {:cont, {:ok, count + length(theorems)}}
        {:error, error} -> {:halt, {:error, {:theorem, module, error}}}
      end
    end)
  end

  defp check_defeqs(env, checks) do
    Enum.reduce_while(checks, :ok, fn check, :ok ->
      case DefeqCheck.check(env, check) do
        :ok -> {:cont, :ok}
        {:error, failed} -> {:halt, {:error, {:defeq, failed}}}
      end
    end)
  end

  defp check_inductives(env, checks) do
    Enum.reduce_while(checks, :ok, fn check, :ok ->
      case InductiveCheck.check(env, check) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {:inductive, check, reason}}}
      end
    end)
  end
end
