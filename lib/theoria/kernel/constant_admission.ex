defmodule Theoria.Kernel.ConstantAdmission do
  @moduledoc "Trusted-adjacent admission checks for constants and axioms."

  alias Theoria.Context
  alias Theoria.Env
  alias Theoria.Env.{Constructor, Inductive, Matcher, Recursor, Reduction}
  alias Theoria.Error
  alias Theoria.Kernel
  alias Theoria.Kernel.AdmissionChecks
  alias Theoria.Kernel.RecursorRules
  alias Theoria.Term
  alias Theoria.Term.Sort

  @spec add_constant(Env.t(), Env.name(), Term.t(), [atom()], keyword()) ::
          {:ok, Env.t()} | {:error, Error.t()}
  def add_constant(%Env{} = env, name, type, universe_params \\ [], opts \\ [])
      when is_list(universe_params) and is_list(opts) do
    with :ok <- AdmissionChecks.ensure_fresh_declaration(env, name),
         :ok <- AdmissionChecks.ensure_universe_params(universe_params),
         :ok <-
           ensure_constant_kind(
             Keyword.get(opts, :kind, :constant),
             Keyword.get(opts, :metadata),
             Keyword.get(opts, :reduction)
           ),
         :ok <- ensure_reduction(Keyword.get(opts, :reduction)),
         :ok <-
           ensure_reduction_metadata(
             env,
             Keyword.get(opts, :reduction),
             Keyword.get(opts, :metadata)
           ),
         :ok <- AdmissionChecks.ensure_level_params(type, universe_params),
         {:ok, %Sort{}} <- infer_sort(env, type) do
      {:ok, Env.put_constant(env, name, type, universe_params, opts)}
    end
  end

  @spec add_axiom(Env.t(), Env.name(), Term.t(), [atom()]) :: {:ok, Env.t()} | {:error, Error.t()}
  def add_axiom(%Env{} = env, name, type, universe_params \\ []) when is_list(universe_params) do
    with :ok <- AdmissionChecks.ensure_fresh_declaration(env, name),
         :ok <- AdmissionChecks.ensure_universe_params(universe_params),
         :ok <- AdmissionChecks.ensure_level_params(type, universe_params),
         {:ok, %Sort{}} <- infer_sort(env, type) do
      {:ok, Env.put_axiom(env, name, type, universe_params)}
    end
  end

  defp infer_sort(env, type) do
    case Kernel.infer(env, Context.new(), type) do
      {:ok, %Sort{} = sort} -> {:ok, sort}
      {:ok, actual} -> error(:expected_sort, type: actual)
      {:error, error} -> {:error, error}
    end
  end

  defp ensure_constant_kind(:constant, nil, nil), do: :ok
  defp ensure_constant_kind(:inductive, %Inductive{}, nil), do: :ok
  defp ensure_constant_kind(:constructor, %Constructor{}, nil), do: :ok
  defp ensure_constant_kind(:matcher, %Matcher{}, nil), do: :ok

  defp ensure_constant_kind(:recursor, %Recursor{num_indices: indices}, nil) when indices > 0,
    do: :ok

  defp ensure_constant_kind(:recursor, %Recursor{rules: []}, nil), do: :ok
  defp ensure_constant_kind(:recursor, %Recursor{}, %Reduction.Iota{}), do: :ok

  defp ensure_constant_kind(kind, metadata, reduction) do
    error(:invalid_declaration, kind: kind, metadata: metadata, reduction: reduction)
  end

  defp ensure_reduction(nil), do: :ok
  defp ensure_reduction(%Reduction.Iota{}), do: :ok
  defp ensure_reduction(reduction), do: error(:invalid_reduction, reduction: reduction)

  defp ensure_reduction_metadata(env, nil, %Recursor{num_indices: indices} = recursor)
       when indices > 0,
       do: ensure_recursor_metadata(env, recursor)

  defp ensure_reduction_metadata(_env, nil, _metadata), do: :ok

  defp ensure_reduction_metadata(env, %Reduction.Iota{}, %Recursor{} = recursor),
    do: ensure_recursor_metadata(env, recursor)

  defp ensure_reduction_metadata(_env, reduction, metadata),
    do: error(:invalid_reduction, reduction: reduction, metadata: metadata)

  defp ensure_recursor_metadata(env, %Recursor{} = recursor) do
    with :ok <- ensure_recursor_rule_count(recursor),
         :ok <- ensure_recursor_rule_coverage(env, recursor) do
      ensure_recursor_rules(env, recursor)
    end
  end

  defp ensure_recursor_rule_count(%Recursor{} = recursor) do
    if recursor.num_minors == length(recursor.rules) do
      :ok
    else
      error(:invalid_reduction, reduction: %Reduction.Iota{}, metadata: recursor)
    end
  end

  defp ensure_recursor_rule_coverage(env, %Recursor{} = recursor) do
    with {:ok, inductive} <- recursor_inductive(recursor),
         {:ok, %Inductive{constructors: constructors}} <- Env.fetch_inductive(env, inductive),
         true <- constructors == Enum.map(recursor.rules, & &1.constructor),
         true <- length(constructors) == MapSet.size(MapSet.new(constructors)) do
      :ok
    else
      _other -> error(:invalid_reduction, reduction: %Reduction.Iota{}, metadata: recursor)
    end
  end

  defp ensure_recursor_rules(env, %Recursor{} = recursor) do
    case RecursorRules.validate(env, recursor) do
      :ok -> :ok
      :error -> error(:invalid_reduction, reduction: %Reduction.Iota{}, metadata: recursor)
    end
  end

  defp recursor_inductive(%Recursor{inductives: [inductive]}), do: {:ok, inductive}
  defp recursor_inductive(_recursor), do: :error

  defp error(reason, details), do: {:error, %Error{reason: reason, details: details}}
end
