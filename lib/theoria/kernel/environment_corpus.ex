defmodule Theoria.Kernel.EnvironmentCorpus do
  @moduledoc "Deterministic environment fragments for kernel replay assurance."

  alias Theoria.Env
  alias Theoria.Kernel
  alias Theoria.Level
  alias Theoria.Term

  defmodule InvalidCase do
    @moduledoc "Environment corpus case expected to be rejected by native validation."

    @enforce_keys [:name, :env, :reason]
    defstruct [:name, :env, :reason]

    @type t :: %__MODULE__{name: atom(), env: Env.t(), reason: atom()}
  end

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

    [
      definition_chain(depth),
      let_chain(depth),
      theorem_chain(depth),
      universe_polymorphic_chain(depth)
    ]
  end

  @doc "Returns malformed deterministic environments expected to be rejected."
  @spec invalid_cases(keyword()) :: [InvalidCase.t()]
  def invalid_cases(_opts \\ []) do
    type_name = :InvalidEnvType
    value_name = :invalid_env_value
    type = Term.const(type_name)
    sort_zero = Term.sort(0)

    valid =
      Env.new()
      |> add_axiom!(type_name, sort_zero)
      |> add_axiom!(value_name, type)

    [
      %InvalidCase{
        name: :missing_declaration_index,
        env: %{valid | declarations: [:missing_decl | Env.declarations(valid)]},
        reason: :missing_declaration
      },
      %InvalidCase{
        name: :untracked_declaration,
        env: %{valid | declarations: []},
        reason: :untracked_declaration
      },
      %InvalidCase{
        name: :definition_value_type_mismatch,
        env: Env.put_definition(valid, :bad_definition, type, sort_zero),
        reason: :type_mismatch
      }
    ]
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

    {env, names} = definition_chain_names(env, :env_corpus_chain, depth, type, seed_name)

    [last | _] = names
    theorem_type = Term.eq(type, Term.const(last), seed)
    theorem_proof = Term.refl(Term.const(last))
    env = add_theorem!(env, :env_corpus_chain_normalizes, theorem_type, theorem_proof)

    %Case{name: :definition_chain, env: env, normalize: Enum.map(names, &{&1, Term.const(&1)})}
  end

  @doc "Builds definitions whose values contain lets that normalize to the previous declaration."
  @spec let_chain(pos_integer()) :: Case.t()
  def let_chain(depth) when is_integer(depth) and depth >= 1 do
    type_name = :EnvCorpusLetType
    seed_name = :env_corpus_let_seed
    type = Term.const(type_name)

    env =
      Env.new()
      |> add_axiom!(type_name, Term.sort(0))
      |> add_axiom!(seed_name, type)

    {env, names} =
      Enum.reduce(1..depth, {env, [seed_name]}, fn index, {env, [previous | _] = names} ->
        name = String.to_atom("env_corpus_let_chain_#{index}")
        value = Term.let(:x, type, Term.const(previous), Term.bvar(0))
        env = add_definition!(env, name, type, value)
        {env, [name | names]}
      end)

    %Case{name: :let_chain, env: env, normalize: Enum.map(names, &{&1, Term.const(&1)})}
  end

  @doc "Builds a definition chain with theorem declarations at every step."
  @spec theorem_chain(pos_integer()) :: Case.t()
  def theorem_chain(depth) when is_integer(depth) and depth >= 1 do
    type_name = :EnvCorpusTheoremType
    seed_name = :env_corpus_theorem_seed
    type = Term.const(type_name)
    seed = Term.const(seed_name)

    env =
      Env.new()
      |> add_axiom!(type_name, Term.sort(0))
      |> add_axiom!(seed_name, type)

    {env, names} = definition_chain_names(env, :env_corpus_theorem_chain, depth, type, seed_name)

    env =
      names
      |> Enum.reject(&(&1 == seed_name))
      |> Enum.reduce(env, fn name, env ->
        theorem_type = Term.eq(type, Term.const(name), seed)

        add_theorem!(
          env,
          String.to_atom("#{name}_normalizes"),
          theorem_type,
          Term.refl(Term.const(name))
        )
      end)

    %Case{name: :theorem_chain, env: env, normalize: Enum.map(names, &{&1, Term.const(&1)})}
  end

  @doc "Builds a small universe-polymorphic identity chain."
  @spec universe_polymorphic_chain(pos_integer()) :: Case.t()
  def universe_polymorphic_chain(depth) when is_integer(depth) and depth >= 1 do
    u = Level.param(:u)
    type = Term.sort(u)
    identity_type = Term.forall(:A, type, Term.forall(:x, Term.bvar(0), Term.bvar(1)))
    identity_value = Term.lam(:A, type, Term.lam(:x, Term.bvar(0), Term.bvar(0)))

    env =
      Env.new()
      |> add_definition!(:env_corpus_id, identity_type, identity_value, [:u])

    {env, names} =
      Enum.reduce(1..depth, {env, [:env_corpus_id]}, fn index, {env, [previous | _] = names} ->
        name = String.to_atom("env_corpus_id_chain_#{index}")
        env = add_definition!(env, name, identity_type, Term.const(previous, [u]), [:u])
        {env, [name | names]}
      end)

    %Case{
      name: :universe_polymorphic_chain,
      env: env,
      normalize: Enum.map(names, &{&1, Term.const(&1, [0])})
    }
  end

  defp definition_chain_names(env, prefix, depth, type, seed_name) do
    Enum.reduce(1..depth, {env, [seed_name]}, fn index, {env, [previous | _] = names} ->
      name = String.to_atom("#{prefix}_#{index}")
      env = add_definition!(env, name, type, Term.const(previous))
      {env, [name | names]}
    end)
  end

  defp add_axiom!(env, name, type) do
    case Kernel.add_axiom(env, name, type) do
      {:ok, env} ->
        env

      {:error, reason} ->
        raise "invalid environment corpus axiom #{inspect(name)}: #{inspect(reason)}"
    end
  end

  defp add_definition!(env, name, type, value, universe_params \\ []) do
    case Kernel.add_definition(env, name, type, value, universe_params) do
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
