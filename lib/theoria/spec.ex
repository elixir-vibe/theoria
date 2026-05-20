defmodule Theoria.Spec do
  @moduledoc """
  Elixir-facing specification vocabulary for tool-generated claims.

  `Theoria.Spec` modules are small data/checking helpers for facts produced by
  Reach, ex_ast, Vibe, and similar tools. They are not part of the trusted kernel
  by themselves; selected validated facts can become `Theoria.Obligation`s and
  checked certificates.
  """
end
