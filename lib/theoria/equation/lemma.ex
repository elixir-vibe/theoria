defmodule Theoria.Equation.Lemma do
  @moduledoc "Metadata for an equation lemma generated from compiled equations."

  alias Theoria.Env
  alias Theoria.Equation.Clause
  alias Theoria.Equation.Info
  alias Theoria.Kernel
  alias Theoria.Term
  alias Theoria.Theorem
  alias Theoria.Validation.DefeqCheck

  @enforce_keys [:name, :left, :right]
  defstruct [:name, :left, :right, :source]

  @type t :: %__MODULE__{
          name: atom(),
          left: Term.t(),
          right: Term.t(),
          source: Clause.t() | nil
        }

  @doc "Builds equation-lemma metadata."
  @spec new(atom(), Term.t(), Term.t(), keyword()) :: t()
  def new(name, left, right, opts \\ []) when is_atom(name) do
    %__MODULE__{name: name, left: left, right: right, source: Keyword.get(opts, :source)}
  end

  @doc "Returns the Lean-style theorem name for a definition equation."
  @spec theorem_name(atom(), atom()) :: atom()
  def theorem_name(definition_name, suffix) when is_atom(definition_name) and is_atom(suffix) do
    :"#{definition_name}.eq_#{suffix}"
  end

  @doc "Builds equation-lemma metadata named after a compiled definition."
  @spec for_definition(Info.t(), atom(), Term.t(), Term.t(), keyword()) :: t()
  def for_definition(%Info{name: definition_name}, suffix, left, right, opts \\ [])
      when is_atom(suffix) do
    new(theorem_name(definition_name, suffix), left, right, opts)
  end

  @doc "Turns equation-lemma metadata into a native definitional-equality validation check."
  @spec defeq_check(t(), atom()) :: DefeqCheck.t()
  def defeq_check(%__MODULE__{} = lemma, category) when is_atom(category) do
    DefeqCheck.new(category, Atom.to_string(lemma.name), lemma.left, lemma.right)
  end

  @doc "Turns many equation lemmas into native definitional-equality validation checks."
  @spec defeq_checks(atom(), [t()]) :: [DefeqCheck.t()]
  def defeq_checks(category, lemmas) when is_atom(category),
    do: Enum.map(lemmas, &defeq_check(&1, category))

  @doc "Kernel-checks equation-lemma metadata as a theorem using reflexivity."
  @spec to_theorem(Env.t(), t(), Term.t(), keyword()) ::
          {:ok, Theorem.t()} | {:error, Theoria.Error.t()}
  def to_theorem(%Env{} = env, %__MODULE__{} = lemma, equality_type, opts \\ []) do
    theorem_type = Term.eq(equality_type, lemma.left, lemma.right)
    proof = Term.refl(lemma.left)
    universe_params = Keyword.get(opts, :universe_params, [])

    with :ok <- Kernel.check(env, proof, theorem_type) do
      {:ok,
       %Theorem{
         name: lemma.name,
         type: theorem_type,
         proof: proof,
         universe_params: universe_params
       }}
    end
  end

  @doc "Kernel-checks and installs equation-lemma metadata as an opaque theorem declaration."
  @spec add_to_env(Env.t(), t(), Term.t(), keyword()) ::
          {:ok, Env.t(), Theorem.t()} | {:error, Theoria.Error.t()}
  def add_to_env(%Env{} = env, %__MODULE__{} = lemma, equality_type, opts \\ []) do
    with {:ok, theorem} <- to_theorem(env, lemma, equality_type, opts),
         {:ok, env} <- Theorem.add_to_env(env, theorem) do
      {:ok, env, theorem}
    end
  end

  @doc "Kernel-checks and installs many equation lemmas as opaque theorem declarations."
  @spec add_all_to_env(Env.t(), [t()], Term.t(), keyword()) ::
          {:ok, Env.t(), [Theorem.t()]} | {:error, Theoria.Error.t()}
  def add_all_to_env(%Env{} = env, lemmas, equality_type, opts \\ []) when is_list(lemmas) do
    Enum.reduce_while(lemmas, {:ok, env, []}, fn lemma, {:ok, env, theorems} ->
      case add_to_env(env, lemma, equality_type, opts) do
        {:ok, env, theorem} -> {:cont, {:ok, env, [theorem | theorems]}}
        {:error, error} -> {:halt, {:error, error}}
      end
    end)
    |> case do
      {:ok, env, theorems} -> {:ok, env, Enum.reverse(theorems)}
      {:error, _error} = error -> error
    end
  end
end
