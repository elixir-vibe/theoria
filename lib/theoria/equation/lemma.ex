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
  defstruct [:name, :left, :right, :source, binders: [], equality_type: nil]

  @type binder :: {atom(), Term.t()}

  @type t :: %__MODULE__{
          name: atom(),
          left: Term.t(),
          right: Term.t(),
          source: Clause.t() | nil,
          binders: [binder()],
          equality_type: Term.t() | nil
        }

  @doc "Builds equation-lemma metadata."
  @spec new(atom(), Term.t(), Term.t(), keyword()) :: t()
  def new(name, left, right, opts \\ []) when is_atom(name) do
    %__MODULE__{
      name: name,
      left: left,
      right: right,
      source: Keyword.get(opts, :source),
      binders: Keyword.get(opts, :binders, []),
      equality_type: Keyword.get(opts, :equality_type)
    }
  end

  @doc "Returns the Lean-style theorem name for a definition equation."
  @spec theorem_name(atom(), atom()) :: atom()
  def theorem_name(definition_name, suffix) when is_atom(definition_name) and is_atom(suffix) do
    :"#{definition_name}.eq_#{suffix_name(suffix)}"
  end

  @doc "Builds equation-lemma metadata named after a compiled definition."
  @spec for_definition(Info.t(), atom(), Term.t(), Term.t(), keyword()) :: t()
  def for_definition(%Info{name: definition_name}, suffix, left, right, opts \\ [])
      when is_atom(suffix) do
    new(theorem_name(definition_name, suffix), left, right, opts)
  end

  @doc "Generates known equation lemmas for a supported compiled definition."
  @spec generated_for(Info.t(), keyword()) :: [t()]
  def generated_for(info, opts \\ [])

  def generated_for(%Info{name: :bool_not} = info, _opts) do
    [
      for_definition(info, true, app(:bool_not, bool_true()), bool_false()),
      for_definition(info, false, app(:bool_not, bool_false()), bool_true())
    ]
  end

  def generated_for(%Info{name: :bool_and} = info, _opts) do
    [
      for_definition(info, :true_true, app(:bool_and, bool_true(), bool_true()), bool_true()),
      for_definition(info, :true_false, app(:bool_and, bool_true(), bool_false()), bool_false()),
      for_definition(info, :false_true, app(:bool_and, bool_false(), bool_true()), bool_false()),
      for_definition(info, :false_false, app(:bool_and, bool_false(), bool_false()), bool_false())
    ]
  end

  def generated_for(%Info{name: :bool_or} = info, _opts) do
    [
      for_definition(info, :true_true, app(:bool_or, bool_true(), bool_true()), bool_true()),
      for_definition(info, :true_false, app(:bool_or, bool_true(), bool_false()), bool_true()),
      for_definition(info, :false_true, app(:bool_or, bool_false(), bool_true()), bool_true()),
      for_definition(info, :false_false, app(:bool_or, bool_false(), bool_false()), bool_false())
    ]
  end

  def generated_for(%Info{name: :nat_add} = info, _opts) do
    n = Term.bvar(0)
    m = Term.bvar(1)

    [
      for_definition(info, :zero, app(:nat_add, zero(), n), n,
        binders: [{:n, nat()}],
        equality_type: nat()
      ),
      for_definition(info, :succ, app(:nat_add, succ(m), n), succ(app(:nat_add, m, n)),
        binders: [{:m, nat()}, {:n, nat()}],
        equality_type: nat()
      )
    ]
  end

  def generated_for(%Info{name: :list_length} = info, _opts) do
    list_length = list_constant(:list_length)
    x = Term.bvar(1)
    xs = Term.bvar(0)

    [
      for_definition(info, nil, app_term(list_length, nat(), list_nil()), zero(),
        equality_type: nat()
      ),
      for_definition(
        info,
        :cons,
        app_term(list_length, nat(), list_cons(nat(), x, xs)),
        succ(app_term(list_length, nat(), xs)),
        binders: [{:x, nat()}, {:xs, list_nat()}],
        equality_type: nat()
      )
    ]
  end

  def generated_for(%Info{name: :list_append} = info, _opts) do
    list_append = list_constant(:list_append)
    x = Term.bvar(2)
    xs = Term.bvar(1)
    ys = Term.bvar(0)

    [
      for_definition(info, nil, app_term(list_append, nat(), list_nil(), ys), ys,
        binders: [{:ys, list_nat()}],
        equality_type: list_nat()
      ),
      for_definition(
        info,
        :cons,
        app_term(list_append, nat(), list_cons(nat(), x, xs), ys),
        list_cons(nat(), x, app_term(list_append, nat(), xs, ys)),
        binders: [{:x, nat()}, {:xs, list_nat()}, {:ys, list_nat()}],
        equality_type: list_nat()
      )
    ]
  end

  def generated_for(%Info{}, _opts), do: []

  @doc "Kernel-checks and installs generated equation lemmas for a supported definition."
  @spec add_generated_to_env(Env.t(), atom() | Info.t(), keyword()) ::
          {:ok, Env.t(), [Theorem.t()]} | {:error, term()}
  def add_generated_to_env(env, equation, opts \\ [])

  def add_generated_to_env(%Env{} = env, name, opts) when is_atom(name) do
    with {:ok, info} <- Info.fetch(env, name) do
      add_generated_to_env(env, info, opts)
    end
  end

  def add_generated_to_env(%Env{} = env, %Info{} = info, opts) do
    lemmas = generated_for(info, opts)

    if lemmas == [] do
      {:error, {:unsupported_equation_definition, info.name}}
    else
      add_all_to_env(env, lemmas, equality_type_for!(info), opts)
    end
  end

  @doc "Returns the equality type used by generated closed equation lemmas."
  @spec equality_type_for!(Info.t()) :: Term.t()
  def equality_type_for!(%Info{name: name}) when name in [:bool_not, :bool_and, :bool_or],
    do: bool()

  def equality_type_for!(%Info{name: :nat_add}), do: nat()
  def equality_type_for!(%Info{name: :list_length}), do: nat()
  def equality_type_for!(%Info{name: :list_append}), do: list_nat()

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
  @spec to_theorem(Env.t(), t(), Term.t() | keyword(), keyword()) ::
          {:ok, Theorem.t()} | {:error, Theoria.Error.t()}
  def to_theorem(%Env{} = env, %__MODULE__{} = lemma, equality_or_opts \\ [], opts \\ []) do
    {equality_type, opts} = equality_type_and_opts(lemma, equality_or_opts, opts)
    theorem_type = forall_many(lemma.binders, Term.eq(equality_type, lemma.left, lemma.right))
    proof = lam_many(lemma.binders, Term.refl(lemma.left))
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
  @spec add_to_env(Env.t(), t(), Term.t() | keyword(), keyword()) ::
          {:ok, Env.t(), Theorem.t()} | {:error, Theoria.Error.t()}
  def add_to_env(%Env{} = env, %__MODULE__{} = lemma, equality_or_opts \\ [], opts \\ []) do
    with {:ok, theorem} <- to_theorem(env, lemma, equality_or_opts, opts),
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

  defp equality_type_and_opts(%__MODULE__{} = lemma, opts, []) when is_list(opts) do
    {lemma.equality_type || Keyword.fetch!(opts, :equality_type), opts}
  end

  defp equality_type_and_opts(_lemma, equality_type, opts), do: {equality_type, opts}

  defp forall_many(binders, body) do
    Enum.reduce(Enum.reverse(binders), body, fn {name, type}, body ->
      Term.forall(name, type, body)
    end)
  end

  defp lam_many(binders, body) do
    Enum.reduce(Enum.reverse(binders), body, fn {name, type}, body ->
      Term.lam(name, type, body)
    end)
  end

  defp suffix_name(nil), do: "nil"
  defp suffix_name(suffix), do: Atom.to_string(suffix)

  defp app(name, arg), do: Term.app(Term.const(name), arg)
  defp app(name, arg1, arg2), do: Term.const(name) |> Term.app(arg1) |> Term.app(arg2)

  defp app_term(fun, arg1, arg2), do: fun |> Term.app(arg1) |> Term.app(arg2)

  defp app_term(fun, arg1, arg2, arg3),
    do: fun |> Term.app(arg1) |> Term.app(arg2) |> Term.app(arg3)

  defp bool, do: Term.const(:Bool)
  defp bool_true, do: Term.const(true)
  defp bool_false, do: Term.const(false)
  defp nat, do: Term.const(:Nat)
  defp zero, do: Term.const(:zero)
  defp succ(term), do: Term.app(Term.const(:succ), term)
  defp list_nat, do: Term.app(list_constant(:List), nat())
  defp list_nil, do: Term.app(list_constant(:list_nil), nat())

  defp list_cons(type, head, tail) do
    list_constant(:list_cons)
    |> Term.app(type)
    |> Term.app(head)
    |> Term.app(tail)
  end

  defp list_constant(name), do: Term.const(name, [1])
end
