defmodule Theoria.Equation do
  @moduledoc """
  Experimental equation API facade.

  `Theoria.Equation` exposes the supported Bool/Nat/List recursor fragment and
  generated-equation registry helpers. It is not yet a public pattern-matching
  language: callers still construct core terms and explicit clauses, while the
  compiler handles coverage, pattern-shape validation, and recursor assembly.

  Experimental before 1.0; prefer this facade over depending on nested
  `Theoria.Equation.*` implementation modules directly.
  """

  alias Theoria.Env
  alias Theoria.Equation.Compiler
  alias Theoria.Equation.Extension
  alias Theoria.Equation.Recursor.Application, as: RecursorApplication

  defdelegate bool_rec(motive, on_true, on_false, major), to: RecursorApplication
  defdelegate nat_rec(motive, zero_case, succ_case, major), to: RecursorApplication
  defdelegate list_rec(element_type, motive, nil_case, cons_case, major), to: RecursorApplication

  defdelegate list_rec(element_type, motive, nil_case, cons_case, major, levels),
    to: RecursorApplication

  defdelegate compile(kind, motive, clauses, major), to: Compiler
  defdelegate compile_definition(kind, signature, motive, clauses, major, opts), to: Compiler
  defdelegate compile_bool(motive, clauses, major), to: Compiler
  defdelegate compile_bool(motive, clauses, major, context), to: Compiler
  defdelegate compile_nat(motive, clauses, major), to: Compiler
  defdelegate compile_list(element_type, motive, clauses, major), to: Compiler
  defdelegate compile_list(element_type, motive, clauses, major, levels), to: Compiler

  @doc "Builds a generated equation registry snapshot from an environment."
  @spec registry(Env.t()) :: Extension.Registry.t()
  def registry(%Env{} = env), do: Extension.build(env)

  @doc "Returns a compact generated equation registry summary."
  @spec summary(Env.t() | Extension.Registry.t()) :: Theoria.Equation.Summary.t()
  def summary(env_or_registry), do: Extension.summary(env_or_registry)

  @doc "Returns ordinary generated equation identities for a source definition in an environment."
  @spec identities(Env.t(), atom()) :: {:ok, [Theoria.Equation.Identity.t()]} | {:error, term()}
  def identities(%Env{} = env, source), do: Extension.equation_ids(env, source)

  @doc "Returns the generated unfold identity for a source definition."
  @spec unfold_identity(Env.t(), atom()) ::
          {:ok, Theoria.Equation.Identity.t()} | {:error, term()}
  def unfold_identity(%Env{} = env, source), do: Extension.unfold_id(env, source)

  @doc "Returns all generated theorem identities known to an environment."
  @spec all_identities(Env.t()) :: [Theoria.Equation.Identity.t()]
  def all_identities(%Env{} = env), do: Extension.theorem_ids(env)

  @doc "Realizes one generated equation theorem without installing it."
  @spec realize(Env.t(), term()) :: {:ok, Theoria.Theorem.t()} | {:error, term()}
  def realize(%Env{} = env, identity), do: Extension.realize(env, identity)

  @doc "Realizes every generated equation theorem known to the environment."
  @spec realize_all(Env.t()) :: {:ok, [Theoria.Theorem.t()]} | {:error, term()}
  def realize_all(%Env{} = env), do: Extension.realize_all(env)
end
