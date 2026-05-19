defmodule Theoria.Kernel.Spec do
  @moduledoc "Elixir-authored metadata for Theoria's trusted kernel fragment."

  @syntax [
    sort: [:level],
    const: [:name, :levels],
    app: [:fun, :arg],
    lam: [:name, :domain, :body],
    forall: [:name, :domain, :body],
    bvar: [:index],
    eq: [:type, :left, :right],
    refl: [:value]
  ]

  @judgments [:infer, :check, :defeq]

  @supported_terms Keyword.keys(@syntax)
  @unsupported_terms [:let, :eq_rec]

  @doc "Returns the term constructors in the first reference-checker fragment."
  @spec syntax() :: keyword([atom()])
  def syntax, do: @syntax

  @doc "Returns the kernel judgments covered by the spec metadata."
  @spec judgments() :: [atom()]
  def judgments, do: @judgments

  @doc "Returns term constructor tags currently supported by the reference checker."
  @spec supported_terms() :: [atom()]
  def supported_terms, do: @supported_terms

  @doc "Returns term constructor tags intentionally left for later reference-checker phases."
  @spec unsupported_terms() :: [atom()]
  def unsupported_terms, do: @unsupported_terms
end
