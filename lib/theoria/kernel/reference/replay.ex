defmodule Theoria.Kernel.Reference.Replay do
  @moduledoc "Reference replay of checked environment declarations."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Kernel.Reference
  alias Theoria.Term.Sort

  defmodule Report do
    @moduledoc "Reference environment replay summary."

    @enforce_keys [:checked, :skipped, :failures]
    defstruct [:checked, :skipped, :failures]

    @type failure :: {Env.name(), atom(), term()}
    @type t :: %__MODULE__{
            checked: non_neg_integer(),
            skipped: non_neg_integer(),
            failures: [failure()]
          }

    @spec ok?(t()) :: boolean()
    def ok?(%__MODULE__{failures: failures}), do: failures == []
  end

  @doc "Replays an environment declaration-by-declaration through the reference checker."
  @spec run(Env.t()) :: Report.t()
  def run(%Env{} = env) do
    env
    |> Env.declarations()
    |> Enum.reduce_while({Env.new(), 0, 0}, fn name, {replay_env, checked, skipped} ->
      case replay_declaration(env, replay_env, name) do
        {:ok, replay_env} -> {:cont, {replay_env, checked + 1, skipped}}
        {:error, failure} -> {:halt, {:error, checked, skipped, [failure]}}
      end
    end)
    |> report()
  end

  defp report({%Env{}, checked, skipped}),
    do: %Report{checked: checked, skipped: skipped, failures: []}

  defp report({:error, checked, skipped, failures}),
    do: %Report{checked: checked, skipped: skipped, failures: failures}

  defp replay_declaration(source_env, replay_env, name) do
    case Env.fetch(source_env, name) do
      {:ok, %Constant{} = constant} -> replay_constant(replay_env, name, constant)
      :error -> {:error, {name, :missing_declaration, :error}}
    end
  end

  defp replay_constant(env, name, %Constant{kind: :axiom} = constant) do
    with :ok <- check_type(env, name, constant) do
      {:ok, Env.put_axiom(env, name, constant.type, constant.universe_params)}
    end
  end

  defp replay_constant(env, name, %Constant{kind: :definition} = constant) do
    with :ok <- check_type(env, name, constant),
         :ok <- check_value(env, name, constant) do
      {:ok,
       Env.put_definition(env, name, constant.type, constant.value, constant.universe_params,
         metadata: constant.metadata
       )}
    end
  end

  defp replay_constant(env, name, %Constant{kind: :theorem} = constant) do
    with :ok <- check_type(env, name, constant),
         :ok <- check_value(env, name, constant) do
      {:ok, Env.put_theorem(env, name, constant.type, constant.value, constant.universe_params)}
    end
  end

  defp replay_constant(env, name, %Constant{kind: :matcher} = constant) do
    with :ok <- check_type(env, name, constant),
         :ok <- check_value(env, name, constant) do
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

  defp replay_constant(env, name, %Constant{} = constant) do
    with :ok <- check_type(env, name, constant) do
      {:ok,
       Env.put_constant(env, name, constant.type, constant.universe_params,
         kind: constant.kind,
         metadata: constant.metadata,
         reduction: constant.reduction
       )}
    end
  end

  defp check_type(env, name, %Constant{type: type}) do
    case Reference.infer(env, type) do
      {:ok, %Sort{}} -> :ok
      {:ok, other} -> {:error, {name, :type_not_sort, other}}
      {:error, reason} -> {:error, {name, :type_error, reason}}
    end
  end

  defp check_value(_env, _name, %Constant{value: nil}), do: :ok

  defp check_value(env, name, %Constant{type: type, value: value}) do
    case Reference.check(env, value, type) do
      :ok -> :ok
      {:error, reason} -> {:error, {name, :value_error, reason}}
    end
  end
end
