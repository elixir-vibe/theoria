defmodule Theoria.Equation.Summary do
  @moduledoc """
  Compact summary of generated equation metadata known to an environment.

  The struct is returned by `Theoria.Equation.summary/1` and records counts for
  ordinary equation lemmas, matcher equations, unfold lemmas, and all generated
  theorem identities. It is intended for diagnostics, reports, and lightweight
  public API checks; use `Theoria.Equation.identities/2` and related facade
  helpers when callers need the actual identities.
  """

  @type t :: %__MODULE__{
          definitions: non_neg_integer(),
          matchers: non_neg_integer(),
          ordinary_equations: non_neg_integer(),
          matcher_equations: non_neg_integer(),
          unfolds: non_neg_integer(),
          theorems: non_neg_integer()
        }

  @enforce_keys [
    :definitions,
    :matchers,
    :ordinary_equations,
    :matcher_equations,
    :unfolds,
    :theorems
  ]
  defstruct @enforce_keys

  @doc "Returns the number of equation-bearing definitions."
  @spec definitions(t()) :: non_neg_integer()
  def definitions(%__MODULE__{definitions: definitions}), do: definitions

  @doc "Returns the number of checked matcher declarations."
  @spec matchers(t()) :: non_neg_integer()
  def matchers(%__MODULE__{matchers: matchers}), do: matchers

  @doc "Returns the number of ordinary generated equation identities."
  @spec ordinary_equations(t()) :: non_neg_integer()
  def ordinary_equations(%__MODULE__{ordinary_equations: ordinary_equations}),
    do: ordinary_equations

  @doc "Returns the number of generated matcher equation identities."
  @spec matcher_equations(t()) :: non_neg_integer()
  def matcher_equations(%__MODULE__{matcher_equations: matcher_equations}), do: matcher_equations

  @doc "Returns the number of generated unfold identities."
  @spec unfolds(t()) :: non_neg_integer()
  def unfolds(%__MODULE__{unfolds: unfolds}), do: unfolds

  @doc "Returns the number of generated theorem identities."
  @spec theorems(t()) :: non_neg_integer()
  def theorems(%__MODULE__{theorems: theorems}), do: theorems
end
