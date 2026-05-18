defmodule Theoria.Equation.Matcher.Indexed.Realization do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Realization planning for indexed matcher equations."

  alias Theoria.Equation.Matcher.Indexed.Package
  alias Theoria.Kernel
  alias Theoria.Term
  alias Theoria.Theorem

  defmodule EquationPlan do
    @moduledoc "Realization plan for one indexed matcher equation."

    @enforce_keys [
      :name,
      :constructor,
      :statement_type,
      :lemma,
      :proof_strategy,
      :realizable?,
      :blockers
    ]
    defstruct [
      :name,
      :constructor,
      :statement_type,
      :lemma,
      :proof_strategy,
      :realizable?,
      :blockers
    ]

    @type t :: %__MODULE__{
            name: atom(),
            constructor: atom(),
            statement_type: Theoria.Term.t(),
            lemma: Theoria.Equation.Lemma.t() | nil,
            proof_strategy: atom(),
            realizable?: boolean(),
            blockers: [atom()]
          }
  end

  defmodule Plan do
    @moduledoc "Realization plan for an indexed matcher equation package."

    @enforce_keys [:matcher, :equations, :realizable?, :blockers]
    defstruct [:matcher, :equations, :realizable?, :blockers]

    @type t :: %__MODULE__{
            matcher: atom(),
            equations: [EquationPlan.t()],
            realizable?: boolean(),
            blockers: [atom()]
          }
  end

  @proof_strategy :recursor_iota_refl

  @doc "Builds the current proof plan for indexed matcher equations."
  @spec plan(Package.t()) :: {:ok, Plan.t()}
  def plan(%Package{} = package) do
    equations = Enum.map(package.statements, &equation_plan(&1, package))

    {:ok,
     %Plan{
       matcher: package.matcher.name,
       equations: equations,
       realizable?: Enum.all?(equations, & &1.realizable?),
       blockers: package_blockers(equations)
     }}
  end

  @doc "Returns true only when every indexed matcher equation has an implemented proof plan."
  @spec realizable?(Plan.t()) :: boolean()
  def realizable?(%Plan{} = plan), do: plan.realizable?

  @doc "Returns the unique blocking reasons in declaration order."
  @spec blockers(Plan.t()) :: [atom()]
  def blockers(%Plan{blockers: blockers}), do: blockers

  @doc "Realizes one indexed matcher equation theorem without installing it."
  @spec realize(Package.t(), atom()) :: {:ok, Theorem.t()} | {:error, term()}
  def realize(%Package{} = package, equation_name) when is_atom(equation_name) do
    with {:ok, plan} <- plan(package),
         %EquationPlan{} = equation_plan <- find_plan(plan, equation_name),
         {:ok, proof} <- proof_for(package, equation_plan),
         theorem = %Theorem{
           name: equation_plan.name,
           type: equation_plan.statement_type,
           proof: proof
         },
         :ok <- Kernel.check(package.env, theorem.proof, theorem.type) do
      {:ok, theorem}
    else
      nil -> {:error, {:unknown_indexed_matcher_equation, equation_name}}
      {:error, _reason} = error -> error
    end
  end

  @doc "Realizes every indexed matcher equation theorem without installing it."
  @spec realize_all(Package.t()) :: {:ok, [Theorem.t()]} | {:error, term()}
  def realize_all(%Package{} = package) do
    package.statements
    |> Enum.reduce_while({:ok, []}, fn equation, {:ok, theorems} ->
      case realize(package, equation.name) do
        {:ok, theorem} -> {:cont, {:ok, [theorem | theorems]}}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
    |> case do
      {:ok, theorems} -> {:ok, Enum.reverse(theorems)}
      {:error, _reason} = error -> error
    end
  end

  defp equation_plan(equation, package) do
    proof = proof_term(equation.statement_type)
    realizable? = Kernel.check(package.env, proof, equation.statement_type) == :ok

    %EquationPlan{
      name: equation.name,
      constructor: equation.constructor,
      statement_type: equation.statement_type,
      lemma: Enum.find(package.lemmas, &(&1.name == equation.name)),
      proof_strategy: @proof_strategy,
      realizable?: realizable?,
      blockers: if(realizable?, do: [], else: [:proof_check_failed])
    }
  end

  defp proof_for(package, %EquationPlan{} = equation_plan) do
    proof = proof_term(equation_plan.statement_type)

    case Kernel.check(package.env, proof, equation_plan.statement_type) do
      :ok ->
        {:ok, proof}

      {:error, reason} ->
        {:error, {:indexed_matcher_proof_check_failed, equation_plan.name, reason}}
    end
  end

  defp proof_term(%Term.Forall{name: name, domain: domain, body: body}) do
    Term.lam(name, domain, proof_term(body))
  end

  defp proof_term(%Term.Eq{left: left}), do: Term.refl(left)

  defp find_plan(%Plan{equations: equations}, equation_name),
    do: Enum.find(equations, &(&1.name == equation_name))

  defp package_blockers(equations) do
    equations
    |> Enum.flat_map(& &1.blockers)
    |> Enum.uniq()
  end
end
