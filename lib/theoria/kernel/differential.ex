defmodule Theoria.Kernel.Differential do
  @moduledoc "Production/reference kernel differential checks."

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Kernel.Corpus
  alias Theoria.Kernel.Reference
  alias Theoria.Term

  defmodule Report do
    @moduledoc "Summary of kernel differential checks."

    @enforce_keys [:infer_count, :check_count, :failures]
    defstruct [:infer_count, :check_count, :failures]

    @type failure :: {atom(), atom(), term(), term()}
    @type t :: %__MODULE__{
            infer_count: non_neg_integer(),
            check_count: non_neg_integer(),
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

  @doc "Runs the default kernel differential corpus."
  @spec run(Env.t()) :: Report.t()
  def run(%Env{} = env) do
    infer_failures =
      Enum.flat_map(Corpus.infer_cases(), fn {name, term} ->
        case compare_infer(env, name, term) do
          :ok -> []
          {:error, failure} -> [failure]
        end
      end)

    check_failures =
      Enum.flat_map(Corpus.check_cases(), fn {name, term, type} ->
        case compare_check(env, name, term, type) do
          :ok -> []
          {:error, failure} -> [failure]
        end
      end)

    %Report{
      infer_count: length(Corpus.infer_cases()),
      check_count: length(Corpus.check_cases()),
      failures: infer_failures ++ check_failures
    }
  end

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
end
