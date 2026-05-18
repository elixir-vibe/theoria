defmodule Theoria.Equation.Matcher.Indexed.Realization do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Realization planning for indexed matcher equations."

  alias Theoria.Equation.Matcher.Indexed.Package

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

  @default_blockers [:proof_term_generation_not_implemented]
  @default_strategy :recursor_iota_refl

  @doc "Builds the current non-realizing proof plan for indexed matcher equations."
  @spec plan(Package.t()) :: {:ok, Plan.t()} | {:error, term()}
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

  defp equation_plan(equation, package) do
    %EquationPlan{
      name: equation.name,
      constructor: equation.constructor,
      statement_type: equation.statement_type,
      lemma: Enum.find(package.lemmas, &(&1.name == equation.name)),
      proof_strategy: @default_strategy,
      realizable?: false,
      blockers: @default_blockers
    }
  end

  defp package_blockers(equations) do
    equations
    |> Enum.flat_map(& &1.blockers)
    |> Enum.uniq()
  end
end
