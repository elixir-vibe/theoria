defmodule Theoria.Equation.Report do
  @moduledoc """
  Structured report for generated equation metadata selected from an environment.

  `mix theoria.equations --json` encodes this struct with Jason. The report is
  intentionally small: it describes the selected definitions, their structured
  ordinary/unfold/matcher identities, and how many artifacts were realized when
  realization was requested.

      iex> entry = %Theoria.Equation.Report.Entry{
      ...>   definition: :nat_add,
      ...>   identities: [Theoria.Equation.Identity.equation(:nat_add, :succ)],
      ...>   unfold_identity: Theoria.Equation.Identity.unfold(:nat_add),
      ...>   matcher_identities: [],
      ...>   realized: 1
      ...> }
      iex> report = %Theoria.Equation.Report{equations: [entry], registry_entries: 2}
      iex> Theoria.Equation.Report.registry_entries(report)
      2
      iex> Theoria.Equation.Report.Entry.definition(entry)
      :nat_add
  """

  alias Theoria.Env
  alias Theoria.Equation.Eqns
  alias Theoria.Equation.Extension
  alias Theoria.Equation.Identity
  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma
  alias Theoria.Equation.Matcher.Eqns, as: MatcherEqns

  defmodule Entry do
    @moduledoc "One definition entry in a generated equation report."

    @type t :: %__MODULE__{
            definition: atom(),
            identities: [Identity.t()],
            unfold_identity: Identity.t(),
            matcher_identities: [Identity.t()],
            realized: non_neg_integer()
          }

    @enforce_keys [:definition, :identities, :unfold_identity, :matcher_identities, :realized]
    defstruct @enforce_keys

    @doc "Returns the source definition name."
    @spec definition(t()) :: atom()
    def definition(%__MODULE__{definition: definition}), do: definition

    @doc "Returns ordinary generated equation identities."
    @spec identities(t()) :: [Identity.t()]
    def identities(%__MODULE__{identities: identities}), do: identities

    @doc "Returns the generated unfold identity."
    @spec unfold_identity(t()) :: Identity.t()
    def unfold_identity(%__MODULE__{unfold_identity: unfold_identity}), do: unfold_identity

    @doc "Returns generated matcher equation identities."
    @spec matcher_identities(t()) :: [Identity.t()]
    def matcher_identities(%__MODULE__{matcher_identities: matcher_identities}),
      do: matcher_identities

    @doc "Returns the number of realized artifacts for this entry."
    @spec realized(t()) :: non_neg_integer()
    def realized(%__MODULE__{realized: realized}), do: realized
  end

  @type t :: %__MODULE__{
          equations: [Entry.t()],
          registry_entries: non_neg_integer()
        }

  @enforce_keys [:equations, :registry_entries]
  defstruct @enforce_keys

  @doc "Builds a report for selected equation definitions."
  @spec from_equations(Env.t(), [Info.t()], keyword()) :: t()
  def from_equations(%Env{} = env, equations, opts \\ []) when is_list(equations) do
    %__MODULE__{
      equations: Enum.map(equations, &entry(env, &1, opts)),
      registry_entries: registry_entry_count(env, equations)
    }
  end

  @doc "Returns report entries in selection order."
  @spec entries(t()) :: [Entry.t()]
  def entries(%__MODULE__{equations: equations}), do: equations

  @doc "Returns the number of generated registry entries covered by the report."
  @spec registry_entries(t()) :: non_neg_integer()
  def registry_entries(%__MODULE__{registry_entries: registry_entries}), do: registry_entries

  defp entry(env, %Info{} = info, opts) do
    %Entry{
      definition: info.name,
      identities: Extension.equation_ids(info),
      unfold_identity: Lemma.unfold_for(info).identity,
      matcher_identities: info |> MatcherEqns.generated() |> Enum.map(& &1.identity),
      realized: realized_count(env, info, opts)
    }
  end

  defp realized_count(env, info, opts) do
    if Keyword.get(opts, :realize?, false) do
      case Eqns.realize(env, info.name) do
        {:ok, artifacts} when is_list(artifacts) -> length(artifacts)
        {:ok, _artifact} -> 1
        {:error, _reason} -> 0
      end
    else
      0
    end
  end

  defp registry_entry_count(env, equations) do
    ordinary_count =
      Enum.reduce(equations, 0, fn info, count ->
        count + 1 + length(Extension.equation_identities(info))
      end)

    matcher_count =
      env
      |> selected_matchers(equations)
      |> Enum.reduce(0, fn matcher, count ->
        count + length(Extension.matcher_equation_identities(env, matcher))
      end)

    ordinary_count + matcher_count
  end

  defp selected_matchers(env, equations) do
    source_names = MapSet.new(Enum.map(equations, & &1.name))

    env
    |> Env.matchers()
    |> Enum.filter(&MapSet.member?(source_names, &1.source))
  end
end
