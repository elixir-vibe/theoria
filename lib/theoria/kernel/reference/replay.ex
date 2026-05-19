defmodule Theoria.Kernel.Reference.Replay do
  @moduledoc "Reference replay of checked environment declarations."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Kernel.Reference
  alias Theoria.Kernel.Reference.Replay.Failure
  alias Theoria.Term.Sort

  defmodule Report do
    @moduledoc "Reference environment replay summary."

    @enforce_keys [:checked, :skipped, :failures, :env]
    defstruct [:checked, :skipped, :failures, :env]

    @type failure :: Failure.t()
    @type t :: %__MODULE__{
            checked: non_neg_integer(),
            skipped: non_neg_integer(),
            failures: [failure()],
            env: Env.t()
          }

    @spec ok?(t()) :: boolean()
    def ok?(%__MODULE__{failures: failures}), do: failures == []
  end

  @doc "Replays an environment declaration-by-declaration through the reference checker."
  @spec run(Env.t()) :: Report.t()
  def run(%Env{} = env) do
    replay_declarations(env, Env.declarations(env), Env.new(), [], 0, 0)
    |> report()
  end

  defp replay_declarations(_source_env, [], replay_env, _checked_names, checked, skipped),
    do: {replay_env, checked, skipped}

  defp replay_declarations(
         source_env,
         [name | pending],
         replay_env,
         checked_names,
         checked,
         skipped
       ) do
    case replay_declaration(source_env, replay_env, name) do
      {:ok, replay_env} ->
        replay_declarations(
          source_env,
          pending,
          replay_env,
          [name | checked_names],
          checked + 1,
          skipped
        )

      {:error, failure} ->
        failure = Failure.with_replay_context(failure, Enum.reverse(checked_names), pending)
        {:error, replay_env, checked, skipped, [failure]}
    end
  end

  defp report({%Env{} = env, checked, skipped}),
    do: %Report{checked: checked, skipped: skipped, failures: [], env: env}

  defp report({:error, %Env{} = env, checked, skipped, failures}),
    do: %Report{checked: checked, skipped: skipped, failures: failures, env: env}

  defp replay_declaration(source_env, replay_env, name) do
    case Env.fetch(source_env, name) do
      {:ok, %Constant{} = constant} -> replay_constant(source_env, replay_env, name, constant)
      :error -> {:error, Failure.new(source_env, name, :lookup, :missing_declaration)}
    end
  end

  defp replay_constant(source_env, env, name, %Constant{kind: :axiom} = constant) do
    with :ok <- check_type(source_env, env, name, constant) do
      {:ok, Env.put_axiom(env, name, constant.type, constant.universe_params)}
    end
  end

  defp replay_constant(source_env, env, name, %Constant{kind: :definition} = constant) do
    with :ok <- check_type(source_env, env, name, constant),
         :ok <- check_value(source_env, env, name, constant) do
      {:ok,
       Env.put_definition(env, name, constant.type, constant.value, constant.universe_params,
         metadata: constant.metadata
       )}
    end
  end

  defp replay_constant(source_env, env, name, %Constant{kind: :theorem} = constant) do
    with :ok <- check_type(source_env, env, name, constant),
         :ok <- check_value(source_env, env, name, constant) do
      {:ok, Env.put_theorem(env, name, constant.type, constant.value, constant.universe_params)}
    end
  end

  defp replay_constant(source_env, env, name, %Constant{kind: :matcher} = constant) do
    with :ok <- check_type(source_env, env, name, constant),
         :ok <- check_value(source_env, env, name, constant) do
      {:ok,
       Env.put_matcher(
         env,
         name,
         constant.type,
         constant.value,
         constant.universe_params,
         constant.metadata
       )}
    end
  end

  defp replay_constant(source_env, env, name, %Constant{} = constant) do
    with :ok <- check_type(source_env, env, name, constant) do
      {:ok,
       Env.put_constant(env, name, constant.type, constant.universe_params,
         kind: constant.kind,
         metadata: constant.metadata,
         reduction: constant.reduction
       )}
    end
  end

  defp check_type(source_env, env, name, %Constant{type: type}) do
    case Reference.infer(env, type) do
      {:ok, %Sort{}} ->
        :ok

      {:ok, other} ->
        {:error, Failure.new(source_env, name, :type, :type_not_sort, actual: other)}

      {:error, reason} ->
        {:error, Failure.new(source_env, name, :type, reason)}
    end
  end

  defp check_value(_source_env, _env, _name, %Constant{value: nil}), do: :ok

  defp check_value(source_env, env, name, %Constant{type: type, value: value}) do
    case Reference.check(env, value, type) do
      :ok -> :ok
      {:error, reason} -> {:error, Failure.new(source_env, name, :value, reason)}
    end
  end
end
