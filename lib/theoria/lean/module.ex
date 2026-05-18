defmodule Theoria.Lean.Module do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Builds Lean oracle source files from encoded checks."

  alias Theoria.Elaborator
  alias Theoria.Equation.{Info, Lemma}
  alias Theoria.Equation.Matcher.Eqns, as: MatcherEqns
  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Equation.Name
  alias Theoria.Lean.Encode
  alias Theoria.Lean.MirrorPrelude
  alias Theoria.Prelude
  alias Theoria.Term
  alias Theoria.Validation.Corpus
  alias Theoria.Validation.IndexedMatchers

  defstruct checks: []

  @type check ::
          {:proof, String.t(), Term.t(), Term.t()}
          | {:defeq, String.t(), Term.t(), Term.t()}
          | {:type, String.t(), Term.t()}
  @type stats :: %{
          proof: non_neg_integer(),
          defeq: non_neg_integer(),
          type: non_neg_integer(),
          total: non_neg_integer()
        }
  @type t :: %__MODULE__{checks: [check()]}

  @doc "Creates an empty Lean oracle module."
  @spec new() :: t()
  def new, do: %__MODULE__{}

  @doc "Adds a proof check, rendered as `example : type := proof`."
  @spec add_proof_check(t(), String.t(), Term.t(), Term.t()) :: t()
  def add_proof_check(%__MODULE__{checks: checks} = module, name, proof, type) do
    %__MODULE__{module | checks: checks ++ [{:proof, name, proof, type}]}
  end

  @doc "Adds a type check, rendered as `#check (type)` for shape validation."
  @spec add_type_check(t(), String.t(), Term.t()) :: t()
  def add_type_check(%__MODULE__{checks: checks} = module, name, type) do
    %__MODULE__{module | checks: checks ++ [{:type, name, type}]}
  end

  @doc "Adds a definitional-equality check, rendered as `example : left = right := rfl`."
  @spec add_defeq_check(t(), String.t(), Term.t(), Term.t()) :: t()
  def add_defeq_check(%__MODULE__{checks: checks} = module, name, left, right) do
    %__MODULE__{module | checks: checks ++ [{:defeq, name, left, right}]}
  end

  @doc "Builds a Lean module from Theoria's validation corpus."
  @spec from_validation(Corpus.t()) :: {:ok, t()} | {:error, term()}
  def from_validation(%Corpus{} = validation) do
    with {:ok, module} <- add_theorem_modules(new(), validation.theorem_modules),
         {:ok, module} <- add_equation_theorems(module, validation.categories),
         {:ok, module} <- add_indexed_matcher_statement_types(module, validation.categories) do
      {:ok, add_defeq_checks(module, validation.defeq_checks)}
    end
  end

  @doc "Returns proof/defeq check counts."
  @spec stats(t()) :: stats()
  def stats(%__MODULE__{checks: checks}) do
    proof = Enum.count(checks, &match?({:proof, _name, _proof, _type}, &1))
    defeq = Enum.count(checks, &match?({:defeq, _name, _left, _right}, &1))
    type = Enum.count(checks, &match?({:type, _name, _type}, &1))
    %{proof: proof, defeq: defeq, type: type, total: proof + defeq + type}
  end

  @doc "Renders the complete Lean source file."
  @spec render(t()) :: String.t()
  def render(%__MODULE__{checks: checks}) do
    body = Enum.map_join(checks, "\n", &render_check/1)
    MirrorPrelude.source() <> body <> "\nend TheoriaOracle\n"
  end

  defp add_theorem_modules(module, theorem_modules) do
    Enum.reduce_while(theorem_modules, {:ok, module}, fn theorem_module, {:ok, module} ->
      case add_theorem_module(module, theorem_module) do
        {:ok, module} -> {:cont, {:ok, module}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp add_theorem_module(module, theorem_module) do
    theorem_module.__theoria_theorems__()
    |> Enum.reduce_while({:ok, module}, fn theorem_name, {:ok, module} ->
      with {:ok, type} <-
             theorem_module
             |> apply(String.to_existing_atom("#{theorem_name}_type"), [])
             |> Elaborator.elaborate(),
           {:ok, proof} <-
             theorem_module
             |> apply(String.to_existing_atom("#{theorem_name}_proof"), [])
             |> Elaborator.elaborate() do
        name = "#{inspect(theorem_module)}.#{theorem_name}"
        {:cont, {:ok, add_proof_check(module, name, proof, type)}}
      else
        {:error, error} -> {:halt, {:error, {theorem_module, theorem_name, error}}}
      end
    end)
  end

  defp add_equation_theorems(module, categories) do
    with {:ok, env} <- Prelude.env() do
      ordinary = generated_equation_lemmas(env, categories)
      matcher = generated_matcher_equation_lemmas(env, categories)

      add_equation_lemma_theorems(ordinary ++ matcher, env, module)
    end
  end

  defp generated_equation_lemmas(env, categories) do
    env
    |> Info.all()
    |> Enum.filter(&equation_category_enabled?(&1, categories))
    |> Enum.flat_map(&Lemma.generated_for/1)
  end

  defp add_equation_lemma_theorems(lemmas, env, module) do
    Enum.reduce_while(lemmas, {:ok, module}, fn lemma, {:ok, module} ->
      add_equation_lemma_theorem(lemma, env, module)
    end)
  end

  defp generated_matcher_equation_lemmas(env, categories) do
    env
    |> Info.all()
    |> Enum.filter(&equation_category_enabled?(&1, categories))
    |> Enum.flat_map(&MatcherEqns.generated/1)
    |> Enum.map(&MatcherEquation.to_lemma/1)
  end

  defp add_indexed_matcher_statement_types(module, categories) do
    if :vec in categories do
      add_vec_indexed_matcher_statement_types(module)
    else
      {:ok, module}
    end
  end

  defp add_vec_indexed_matcher_statement_types(module) do
    with {:ok, env} <- Prelude.env(),
         {:ok, package} <- IndexedMatchers.check(env) do
      add_indexed_type_checks(module, package.statements)
    end
  end

  defp add_indexed_type_checks(module, statements) do
    Enum.reduce(statements, {:ok, module}, fn equation, {:ok, module} ->
      {:ok,
       add_type_check(module, "indexed.#{Name.format(equation.id)}", equation.statement_type)}
    end)
  end

  defp add_equation_lemma_theorem(lemma, env, module) do
    case Lemma.to_theorem(env, lemma) do
      {:ok, theorem} ->
        {:cont,
         {:ok,
          add_proof_check(
            module,
            "equation.#{equation_lemma_label(lemma)}",
            theorem.proof,
            theorem.type
          )}}

      {:error, error} ->
        {:halt, {:error, {:equation, lemma.name, error}}}
    end
  end

  defp equation_lemma_label(%{id: %Name{} = id}), do: Name.format(id)
  defp equation_lemma_label(%{name: name}), do: Name.format_declaration(name)

  defp equation_category_enabled?(info, categories),
    do: equation_category(info.name) in categories

  defp equation_category(name) when name in [:bool_not, :bool_and, :bool_or], do: :bool
  defp equation_category(:nat_add), do: :nat
  defp equation_category(name) when name in [:list_length, :list_append], do: :list
  defp equation_category(_name), do: :unknown

  defp add_defeq_checks(module, checks) do
    Enum.reduce(checks, module, fn check, module ->
      add_defeq_check(module, check.name, check.left, check.right)
    end)
  end

  defp render_check({:proof, name, proof, type}) do
    """
    -- proof #{name}
    example : #{Encode.term(type)} := #{Encode.term(proof)}
    """
  end

  defp render_check({:defeq, name, left, right}) do
    """
    -- defeq #{name}
    example : #{Encode.term(left)} = #{Encode.term(right)} := rfl
    """
  end

  defp render_check({:type, name, type}) do
    """
    -- type #{name}
    #check (#{Encode.term(type)})
    """
  end
end
