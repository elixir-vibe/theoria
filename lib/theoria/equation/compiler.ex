defmodule Theoria.Equation.Compiler do
  @moduledoc "Constructor-equation compiler for the initial Bool/Nat/List fragment."

  alias Theoria.Equation.Branch
  alias Theoria.Equation.Clause
  alias Theoria.Equation.Compiled
  alias Theoria.Equation.Context
  alias Theoria.Equation.FixedParams
  alias Theoria.Equation.MatcherInfo
  alias Theoria.Equation.Pattern.Constructor
  alias Theoria.Equation.Recursors
  alias Theoria.Equation.Schema
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
          atom(),
          Term.t(),
          [Clause.t()],
          Term.t(),
          keyword()
        ) :: compiled_result()
  def compile_definition(kind, name, motive, clauses, major, opts \\ []) when is_atom(name) do
    with {:ok, body} <- compile_with_context(kind, motive, clauses, major, opts),
         {:ok, schema} <- schema_for(kind, name, opts),
         :ok <- Schema.validate(schema) do
      {:ok,
       %Compiled{
         body: body,
         clauses: clauses,
         schema: schema,
         matcher: MatcherInfo.for_schema(name, schema),
         rec_arg_pos: Keyword.fetch!(opts, :rec_arg_pos),
         fixed_params: Keyword.get(opts, :fixed_params, FixedParams.new())
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
      {:ok, Recursors.bool_rec(motive, on_true, on_false, major)}
    end
  end

  @doc "Compiles Nat zero/succ clauses to a Nat recursor application."
  @spec compile_nat(Term.t(), [Clause.t()], Term.t()) :: result()
  def compile_nat(motive, clauses, major) do
    expected = %{zero: 0, succ: 1}

    with :ok <- Validator.validate_clauses(clauses, expected),
         {:ok, zero_case} <- constructor_body(clauses, :zero, Context.new()),
         {:ok, succ_clause} <- constructor_clause(clauses, :succ) do
      {:ok, Recursors.nat_rec(motive, zero_case, nat_succ_case(succ_clause), major)}
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
       Recursors.list_rec(
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

  defp schema_for(:bool, name, _opts) when name in [:bool_not, :bool_and, :bool_or],
    do: {:ok, bool_schema(name)}

  defp schema_for(:nat, :nat_add, _opts), do: {:ok, nat_add_schema()}

  defp schema_for({:list, _element_type, _levels}, name, _opts)
       when name in [:list_length, :list_append],
       do: {:ok, list_schema(name)}

  defp schema_for(_kind, name, _opts), do: {:error, {:unsupported_equation_schema, name}}

  defp bool_schema(:bool_not) do
    Schema.new(
      :bool,
      [
        Schema.equation(true, app(:bool_not, bool_true()), bool_false(), bool()),
        Schema.equation(false, app(:bool_not, bool_false()), bool_true(), bool())
      ],
      recursive_argument: 0,
      argument_binders: [{:b, bool()}]
    )
  end

  defp bool_schema(:bool_and) do
    Schema.new(
      :bool,
      [
        Schema.equation(
          :true_true,
          app(:bool_and, bool_true(), bool_true()),
          bool_true(),
          bool()
        ),
        Schema.equation(
          :true_false,
          app(:bool_and, bool_true(), bool_false()),
          bool_false(),
          bool()
        ),
        Schema.equation(
          :false_true,
          app(:bool_and, bool_false(), bool_true()),
          bool_false(),
          bool()
        ),
        Schema.equation(
          :false_false,
          app(:bool_and, bool_false(), bool_false()),
          bool_false(),
          bool()
        )
      ],
      recursive_argument: 0,
      argument_binders: [{:a, bool()}, {:b, bool()}]
    )
  end

  defp bool_schema(:bool_or) do
    Schema.new(
      :bool,
      [
        Schema.equation(:true_true, app(:bool_or, bool_true(), bool_true()), bool_true(), bool()),
        Schema.equation(
          :true_false,
          app(:bool_or, bool_true(), bool_false()),
          bool_true(),
          bool()
        ),
        Schema.equation(
          :false_true,
          app(:bool_or, bool_false(), bool_true()),
          bool_true(),
          bool()
        ),
        Schema.equation(
          :false_false,
          app(:bool_or, bool_false(), bool_false()),
          bool_false(),
          bool()
        )
      ],
      recursive_argument: 0,
      argument_binders: [{:a, bool()}, {:b, bool()}]
    )
  end

  defp nat_add_schema do
    n = Term.bvar(0)
    m = Term.bvar(1)

    Schema.new(
      :nat,
      [
        Schema.equation(:zero, app(:nat_add, zero(), n), n, nat(), binders: [{:n, nat()}]),
        Schema.equation(:succ, app(:nat_add, succ(m), n), succ(app(:nat_add, m, n)), nat(),
          binders: [{:m, nat()}, {:n, nat()}]
        )
      ],
      recursive_argument: 0,
      argument_binders: [{:m, nat()}, {:n, nat()}]
    )
  end

  defp list_schema(:list_length) do
    list_length = list_constant(:list_length)
    x = Term.bvar(1)
    xs = Term.bvar(0)

    Schema.new(
      :list,
      [
        Schema.equation(nil, app(list_length, nat(), list_nil(nat())), zero(), nat()),
        Schema.equation(
          :cons,
          app(list_length, nat(), list_cons_schema(nat(), x, xs)),
          succ(app(list_length, nat(), xs)),
          nat(),
          binders: [{:x, nat()}, {:xs, list_of_schema(nat())}]
        )
      ],
      recursive_argument: 1,
      parameter_binders: [{:a, Term.sort(1)}],
      argument_binders: [{:xs, list_of_schema(nat())}]
    )
  end

  defp list_schema(:list_append) do
    list_append = list_constant(:list_append)
    x = Term.bvar(2)
    xs = Term.bvar(1)
    ys = Term.bvar(0)

    Schema.new(
      :list,
      [
        Schema.equation(
          nil,
          app(list_append, nat(), list_nil(nat()), ys),
          ys,
          list_of_schema(nat()),
          binders: [{:ys, list_of_schema(nat())}]
        ),
        Schema.equation(
          :cons,
          app(list_append, nat(), list_cons_schema(nat(), x, xs), ys),
          list_cons_schema(nat(), x, app(list_append, nat(), xs, ys)),
          list_of_schema(nat()),
          binders: [{:x, nat()}, {:xs, list_of_schema(nat())}, {:ys, list_of_schema(nat())}]
        )
      ],
      recursive_argument: 1,
      parameter_binders: [{:a, Term.sort(1)}],
      argument_binders: [{:xs, list_of_schema(nat())}, {:ys, list_of_schema(nat())}]
    )
  end

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

  defp app(name, arg) when is_atom(name), do: Term.app(Term.const(name), arg)

  defp app(name, arg1, arg2) when is_atom(name),
    do: Term.const(name) |> Term.app(arg1) |> Term.app(arg2)

  defp app(fun, arg1, arg2), do: fun |> Term.app(arg1) |> Term.app(arg2)

  defp app(fun, arg1, arg2, arg3),
    do: fun |> Term.app(arg1) |> Term.app(arg2) |> Term.app(arg3)

  defp bool, do: Term.const(:Bool)
  defp bool_true, do: Term.const(true)
  defp bool_false, do: Term.const(false)
  defp nat, do: Term.const(:Nat)
  defp zero, do: Term.const(:zero)
  defp succ(term), do: Term.app(Term.const(:succ), term)
  defp list_constant(name), do: Term.const(name, [1])
  defp list_nil(type), do: Term.app(list_constant(:list_nil), type)
  defp list_of_schema(type), do: Term.app(list_constant(:List), type)

  defp list_cons_schema(type, head, tail) do
    list_constant(:list_cons)
    |> Term.app(type)
    |> Term.app(head)
    |> Term.app(tail)
  end
end
