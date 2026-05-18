defmodule Theoria.Env do
  @moduledoc """
  Kernel environment containing checked constants and definitions.
  """

  alias Theoria.Env.Constant
  alias Theoria.Env.Constructor, as: EnvConstructor
  alias Theoria.Env.Inductive, as: EnvInductive
  alias Theoria.Env.Matcher, as: EnvMatcher
  alias Theoria.Env.Recursor, as: EnvRecursor
  alias Theoria.Term

  defstruct constants: %{}, declarations: []

  @type name :: atom() | struct()
  @type t :: %__MODULE__{constants: %{name() => Constant.t()}, declarations: [name()]}

  @spec new() :: t()
  def new, do: %__MODULE__{}

  @spec fetch(t(), name()) :: {:ok, Constant.t()} | :error
  def fetch(%__MODULE__{constants: constants}, name) do
    Map.fetch(constants, name)
  end

  @spec put_constant(t(), atom(), Term.t(), [atom()], keyword()) :: t()
  def put_constant(
        %__MODULE__{constants: constants} = env,
        name,
        type,
        universe_params \\ [],
        opts \\ []
      )
      when is_list(universe_params) and is_list(opts) do
    %{
      env
      | constants:
          Map.put(constants, name, %Constant{
            type: type,
            kind: Keyword.get(opts, :kind, :constant),
            universe_params: universe_params,
            reduction: Keyword.get(opts, :reduction),
            metadata: Keyword.get(opts, :metadata)
          }),
        declarations: put_order(env, name)
    }
  end

  @spec put_axiom(t(), atom(), Term.t(), [atom()]) :: t()
  def put_axiom(%__MODULE__{constants: constants} = env, name, type, universe_params \\ [])
      when is_list(universe_params) do
    %{
      env
      | constants:
          Map.put(constants, name, %Constant{
            type: type,
            kind: :axiom,
            reducible?: false,
            universe_params: universe_params
          }),
        declarations: put_order(env, name)
    }
  end

  @spec put_definition(t(), atom(), Term.t(), Term.t(), [atom()], keyword()) :: t()
  def put_definition(
        %__MODULE__{constants: constants} = env,
        name,
        type,
        value,
        universe_params \\ [],
        opts \\ []
      )
      when is_list(universe_params) and is_list(opts) do
    %{
      env
      | constants:
          Map.put(constants, name, %Constant{
            type: type,
            value: value,
            kind: :definition,
            reducible?: true,
            universe_params: universe_params,
            metadata: Keyword.get(opts, :metadata)
          }),
        declarations: put_order(env, name)
    }
  end

  @spec put_matcher(t(), atom(), Term.t(), Term.t(), [atom()], EnvMatcher.t()) :: t()
  def put_matcher(
        %__MODULE__{constants: constants} = env,
        name,
        type,
        value,
        universe_params \\ [],
        %EnvMatcher{} = metadata
      )
      when is_list(universe_params) do
    %{
      env
      | constants:
          Map.put(constants, name, %Constant{
            type: type,
            value: value,
            kind: :matcher,
            reducible?: true,
            universe_params: universe_params,
            metadata: metadata
          }),
        declarations: put_order(env, name)
    }
  end

  @spec put_theorem(t(), atom(), Term.t(), Term.t(), [atom()]) :: t()
  def put_theorem(
        %__MODULE__{constants: constants} = env,
        name,
        type,
        proof,
        universe_params \\ []
      )
      when is_list(universe_params) do
    %{
      env
      | constants:
          Map.put(constants, name, %Constant{
            type: type,
            value: proof,
            kind: :theorem,
            reducible?: false,
            universe_params: universe_params
          }),
        declarations: put_order(env, name)
    }
  end

  @spec fetch_inductive(t(), atom()) :: {:ok, EnvInductive.t()} | :error
  def fetch_inductive(%__MODULE__{} = env, name), do: fetch_metadata(env, name, EnvInductive)

  @spec fetch_constructor(t(), atom()) :: {:ok, EnvConstructor.t()} | :error
  def fetch_constructor(%__MODULE__{} = env, name), do: fetch_metadata(env, name, EnvConstructor)

  @spec fetch_recursor(t(), atom()) :: {:ok, EnvRecursor.t()} | :error
  def fetch_recursor(%__MODULE__{} = env, name), do: fetch_metadata(env, name, EnvRecursor)

  @spec fetch_matcher(t(), atom()) :: {:ok, EnvMatcher.t()} | :error
  def fetch_matcher(%__MODULE__{} = env, name), do: fetch_metadata(env, name, EnvMatcher)

  @spec inductive?(t(), atom()) :: boolean()
  def inductive?(%__MODULE__{} = env, name),
    do: match?({:ok, _metadata}, fetch_inductive(env, name))

  @spec constructor?(t(), atom()) :: boolean()
  def constructor?(%__MODULE__{} = env, name),
    do: match?({:ok, _metadata}, fetch_constructor(env, name))

  @spec recursor?(t(), atom()) :: boolean()
  def recursor?(%__MODULE__{} = env, name),
    do: match?({:ok, _metadata}, fetch_recursor(env, name))

  @spec matcher?(t(), atom()) :: boolean()
  def matcher?(%__MODULE__{} = env, name),
    do: match?({:ok, _metadata}, fetch_matcher(env, name))

  @doc "Returns matcher declarations in insertion order."
  @spec matchers(t()) :: [EnvMatcher.t()]
  def matchers(%__MODULE__{} = env) do
    env
    |> declarations()
    |> Enum.flat_map(fn name ->
      case fetch_matcher(env, name) do
        {:ok, matcher} -> [matcher]
        :error -> []
      end
    end)
  end

  @doc "Returns declaration names in insertion order."
  @spec declarations(t()) :: [name()]
  def declarations(%__MODULE__{declarations: declarations}), do: declarations

  defp fetch_metadata(%__MODULE__{} = env, name, module) do
    case fetch(env, name) do
      {:ok, %Constant{metadata: %{__struct__: ^module} = metadata}} -> {:ok, metadata}
      _other -> :error
    end
  end

  defp put_order(%__MODULE__{declarations: declarations}, name) do
    if name in declarations do
      declarations
    else
      declarations ++ [name]
    end
  end
end
