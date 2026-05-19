defmodule Theoria.Kernel.EnvironmentCorpus do
  @moduledoc "Deterministic environment fragments for kernel replay assurance."

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Term

  defmodule Case do
    @moduledoc "Environment corpus case with terms that should normalize under that environment."

    @enforce_keys [:name, :env, :normalize]
    defstruct [:name, :env, :normalize]

    @type normalize_case :: {atom(), Term.t()}
    @type t :: %__MODULE__{name: atom(), env: Env.t(), normalize: [normalize_case()]}
  end

  @doc "Returns deterministic environment cases used by kernel differential assurance."
  @spec cases(keyword()) :: [Case.t()]
  def cases(opts \\ []) do
    depth = Keyword.get(opts, :definition_chain_depth, 4)

    [definition_chain(depth)]
  end

  @doc "Builds a transparent definition chain ending in a theorem over the normalized endpoint."
  @spec definition_chain(pos_integer()) :: Case.t()
  def definition_chain(depth) when is_integer(depth) and depth >= 1 do
    type_name = :EnvCorpusType
    seed_name = :env_corpus_seed
    type = Term.const(type_name)
    seed = Term.const(seed_name)

    env =
      Env.new()
      |> add_axiom!(type_name, Term.sort(0))
      |> add_axiom!(seed_name, type)

    {env, names} =
      Enum.reduce(1..depth, {env, [seed_name]}, fn index, {env, [previous | _] = names} ->
        name = String.to_atom("env_corpus_chain_#{index}")
        env = add_definition!(env, name, type, Term.const(previous))
        {env, [name | names]}
      end)

    [last | _] = names
    theorem_type = Term.eq(type, Term.const(last), seed)
    theorem_proof = Term.refl(Term.const(last))
    env = add_theorem!(env, :env_corpus_chain_normalizes, theorem_type, theorem_proof)

    %Case{
      name: :definition_chain,
      env: env,
      normalize: Enum.map(names, &{&1, Term.const(&1)})
    }
  end

  defp add_axiom!(env, name, type) do
    case Kernel.add_axiom(env, name, type) do
      {:ok, env} ->
        env

      {:error, reason} ->
        raise "invalid environment corpus axiom #{inspect(name)}: #{inspect(reason)}"
    end
  end

  defp add_definition!(env, name, type, value) do
    case Kernel.add_definition(env, name, type, value) do
      {:ok, env} ->
        env

      {:error, reason} ->
        raise "invalid environment corpus definition #{inspect(name)}: #{inspect(reason)}"
    end
  end

  defp add_theorem!(env, name, type, proof) do
    case Kernel.add_theorem(env, name, type, proof) do
      {:ok, env} ->
        env

      {:error, reason} ->
        raise "invalid environment corpus theorem #{inspect(name)}: #{inspect(reason)}"
    end
  end
end
