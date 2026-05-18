defmodule Theoria.Equation.Compiler do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Internal constructor-equation compiler for the initial Bool/Nat/List fragment."

  alias Theoria.Equation.Branch
  alias Theoria.Equation.Clause
  alias Theoria.Equation.Compiled
  alias Theoria.Equation.Context
  alias Theoria.Equation.Pattern.Constructor
  alias Theoria.Equation.Recursor.Builders, as: RecursorBuilders
  alias Theoria.Equation.Schema.Builder, as: SchemaBuilder
  alias Theoria.Equation.Signature
  alias Theoria.Equation.Validator
  alias Theoria.Level
  alias Theoria.Term

  @type result :: {:ok, Term.t()} | {:error, term()}
  @type compiled_result :: {:ok, Compiled.t()} | {:error, term()}

  @doc "Compiles a supported constructor-equation fragment."
  @spec compile(
          :bool | :nat | {:list, Term.t(), [Level.t() | non_neg_integer()]},
          Term.t(),
          [Clause.t()],
          Term.t()
        ) ::
          result()
  def compile(:bool, motive, clauses, major), do: compile_bool(motive, clauses, major)
  def compile(:nat, motive, clauses, major), do: compile_nat(motive, clauses, major)

  def compile({:list, element_type, levels}, motive, clauses, major),
    do: compile_list(element_type, motive, clauses, major, levels)

  @doc "Compiles a supported constructor-equation fragment and generated metadata."
  @spec compile_definition(
          :bool | :nat | {:list, Term.t(), [Level.t() | non_neg_integer()]},
          Signature.t(),
          Term.t(),
          [Clause.t()],
          Term.t(),
          keyword()
        ) :: compiled_result()
  def compile_definition(kind, %Signature{} = signature, motive, clauses, major, opts \\ []) do
    with {:ok, body} <- compile_with_context(kind, motive, clauses, major, opts),
         {:ok, schema} <- SchemaBuilder.build(signature, Keyword.fetch!(opts, :cases)) do
      {:ok,
       %Compiled{
         body: body,
         clauses: clauses,
         schema: schema,
         matcher: SchemaBuilder.matcher(signature, schema),
         rec_arg_pos: signature.rec_arg_pos,
         fixed_params: signature.fixed_params
       }}
    end
  end

  @doc "Compiles Bool constructor clauses to a Bool recursor application."
  @spec compile_bool(Term.t(), [Clause.t()], Term.t(), Context.t()) :: result()
  def compile_bool(motive, clauses, major, context \\ Context.new()) do
    expected = %{true => 0, false => 0}

    with :ok <- Validator.validate_clauses(clauses, expected),
         {:ok, on_true} <- constructor_body(clauses, true, context),
         {:ok, on_false} <- constructor_body(clauses, false, context) do
      {:ok, RecursorBuilders.bool_rec(motive, on_true, on_false, major)}
    end
  end

  @doc "Compiles Nat zero/succ clauses to a Nat recursor application."
  @spec compile_nat(Term.t(), [Clause.t()], Term.t()) :: result()
  def compile_nat(motive, clauses, major) do
    expected = %{zero: 0, succ: 1}

    with :ok <- Validator.validate_clauses(clauses, expected),
         {:ok, zero_case} <- constructor_body(clauses, :zero, Context.new()),
         {:ok, succ_clause} <- constructor_clause(clauses, :succ) do
      {:ok,
       RecursorBuilders.nat_rec(
         motive,
         zero_case,
         nat_succ_case(succ_clause),
         major
       )}
    end
  end

  @doc "Compiles List nil/cons clauses to a List recursor application."
  @spec compile_list(Term.t(), Term.t(), [Clause.t()], Term.t(), [Level.t() | non_neg_integer()]) ::
          result()
  def compile_list(element_type, motive, clauses, major, levels \\ [1, 1]) do
    expected = %{list_nil: 0, list_cons: 2}

    with :ok <- Validator.validate_clauses(clauses, expected),
         {:ok, nil_case} <- constructor_body(clauses, :list_nil, Context.new()),
         {:ok, cons_clause} <- constructor_clause(clauses, :list_cons) do
      {:ok,
       RecursorBuilders.list_rec(
         element_type,
         motive,
         nil_case,
         list_cons_case(cons_clause, element_type, motive),
         major,
         levels
       )}
    end
  end

  defp compile_with_context(:bool, motive, clauses, major, opts),
    do: compile_bool(motive, clauses, major, Keyword.get(opts, :context, Context.new()))

  defp compile_with_context(:nat, motive, clauses, major, _opts),
    do: compile_nat(motive, clauses, major)

  defp compile_with_context({:list, element_type, levels}, motive, clauses, major, _opts),
    do: compile_list(element_type, motive, clauses, major, levels)

  defp constructor_body(clauses, constructor, context) do
    with {:ok, %Clause{} = clause} <- constructor_clause(clauses, constructor) do
      {:ok, Clause.materialize(clause, context)}
    end
  end

  defp constructor_clause(clauses, constructor) do
    clauses
    |> Enum.find(&constructor_clause?(&1, constructor))
    |> case do
      %Clause{} = clause -> {:ok, clause}
      nil -> {:error, {:missing_clause, constructor}}
    end
  end

  defp constructor_clause?(%Clause{patterns: [%Constructor{name: name}]}, name), do: true
  defp constructor_clause?(_clause, _constructor), do: false

  defp nat_succ_case(%Clause{body: %Term.Lam{} = body}), do: body

  defp nat_succ_case(%Clause{} = clause) do
    branch = Branch.nat_succ(clause)

    clause
    |> Clause.materialize(branch.context)
    |> then(&Branch.wrap(branch, &1))
  end

  defp list_cons_case(%Clause{body: %Term.Lam{} = body}, _element_type, _motive), do: body

  defp list_cons_case(%Clause{} = clause, element_type, motive) do
    branch = Branch.list_cons(clause, element_type, motive)

    clause
    |> Clause.materialize(branch.context)
    |> then(&Branch.wrap(branch, &1))
  end
end
