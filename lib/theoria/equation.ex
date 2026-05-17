defmodule Theoria.Equation do
  @moduledoc """
  Small internal helpers for compiling constructor equations to recursor terms.

  This is deliberately not a surface equation compiler yet. It centralizes the
  core recursor shapes used by library definitions so later equation syntax can
  target one implementation path.
  """

  alias Theoria.Term

  defmodule Pattern do
    @moduledoc "Equation compiler patterns."

    defmodule Var do
      @moduledoc "A variable pattern."
      @enforce_keys [:name]
      defstruct [:name]

      @type t :: %__MODULE__{name: atom()}
    end

    defmodule Wildcard do
      @moduledoc "A wildcard pattern."
      defstruct []

      @type t :: %__MODULE__{}
    end

    defmodule Constructor do
      @moduledoc "A constructor pattern with subpatterns."
      @enforce_keys [:name]
      defstruct [:name, args: []]

      @type t :: %__MODULE__{name: atom(), args: [Pattern.t()]}
    end

    @type t :: Var.t() | Wildcard.t() | Constructor.t()

    @doc "Builds a variable pattern."
    @spec var(atom()) :: Var.t()
    def var(name) when is_atom(name), do: %Var{name: name}

    @doc "Builds a wildcard pattern."
    @spec wildcard() :: Wildcard.t()
    def wildcard, do: %Wildcard{}

    @doc "Builds a constructor pattern."
    @spec constructor(atom(), [t()]) :: Constructor.t()
    def constructor(name, args \\ []) when is_atom(name) and is_list(args) do
      %Constructor{name: name, args: args}
    end
  end

  defmodule Clause do
    @moduledoc "A constructor equation clause."
    @enforce_keys [:patterns, :body]
    defstruct [:patterns, :body]

    @type t :: %__MODULE__{patterns: [Pattern.t()], body: Term.t()}

    @doc "Builds an equation clause."
    @spec new([Pattern.t()], Term.t()) :: t()
    def new(patterns, body) when is_list(patterns),
      do: %__MODULE__{patterns: patterns, body: body}
  end

  alias Theoria.Equation.Clause
  alias Theoria.Equation.Pattern.Constructor

  @doc "Builds a Bool recursor application from the two constructor equations."
  @spec bool(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.t()
  def bool(motive, on_true, on_false, major) do
    Term.const(:bool_rec, [1])
    |> Term.app(motive)
    |> Term.app(on_true)
    |> Term.app(on_false)
    |> Term.app(major)
  end

  @doc "Compiles Bool constructor clauses to a Bool recursor application."
  @spec compile_bool(Term.t(), [Clause.t()], Term.t()) :: {:ok, Term.t()} | {:error, term()}
  def compile_bool(motive, clauses, major) do
    with {:ok, on_true} <- constructor_body(clauses, true, 0),
         {:ok, on_false} <- constructor_body(clauses, false, 0) do
      {:ok, bool(motive, on_true, on_false, major)}
    end
  end

  @doc "Builds a Nat recursor application from zero/succ equations."
  @spec nat(Term.t(), Term.t(), Term.t(), Term.t()) :: Term.t()
  def nat(motive, zero_case, succ_case, major) do
    Term.const(:nat_rec, [1])
    |> Term.app(motive)
    |> Term.app(zero_case)
    |> Term.app(succ_case)
    |> Term.app(major)
  end

  @doc "Compiles Nat zero/succ clauses to a Nat recursor application."
  @spec compile_nat(Term.t(), [Clause.t()], Term.t()) :: {:ok, Term.t()} | {:error, term()}
  def compile_nat(motive, clauses, major) do
    with {:ok, zero_case} <- constructor_body(clauses, :zero, 0),
         {:ok, succ_case} <- constructor_body(clauses, :succ, 1) do
      {:ok, nat(motive, zero_case, succ_case, major)}
    end
  end

  @doc "Builds a List recursor application from nil/cons equations."
  @spec list(Term.t(), Term.t(), Term.t(), Term.t(), Term.t()) :: Term.t()
  def list(element_type, motive, nil_case, cons_case, major) do
    Term.const(:list_rec, [1, 1])
    |> Term.app(element_type)
    |> Term.app(motive)
    |> Term.app(nil_case)
    |> Term.app(cons_case)
    |> Term.app(major)
  end

  @doc "Compiles List nil/cons clauses to a List recursor application."
  @spec compile_list(Term.t(), Term.t(), [Clause.t()], Term.t()) ::
          {:ok, Term.t()} | {:error, term()}
  def compile_list(element_type, motive, clauses, major) do
    with {:ok, nil_case} <- constructor_body(clauses, :list_nil, 0),
         {:ok, cons_case} <- constructor_body(clauses, :list_cons, 2) do
      {:ok, list(element_type, motive, nil_case, cons_case, major)}
    end
  end

  defp constructor_body(clauses, constructor, arity) do
    clauses
    |> Enum.find(&constructor_clause?(&1, constructor, arity))
    |> case do
      %Clause{body: body} -> {:ok, body}
      nil -> {:error, {:missing_clause, constructor}}
    end
  end

  defp constructor_clause?(%Clause{patterns: [%Constructor{name: name, args: args}]}, name, arity) do
    length(args) == arity
  end

  defp constructor_clause?(_clause, _constructor, _arity), do: false
end
