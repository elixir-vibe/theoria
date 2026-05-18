defmodule Theoria.Equation do
  @moduledoc """
  Experimental/internal API for 0.2; subject to change before 0.3.

  Internal constructor-equation compiler facade.

  `Theoria.Equation` supports the current Bool/Nat/List recursor fragment. It is
  not yet a public pattern-matching language: callers still construct core terms
  and explicit clauses, while the compiler handles coverage, pattern-shape
  validation, and recursor assembly.
  """

  alias Theoria.Equation.Compiler
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
end
