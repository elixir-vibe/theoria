defmodule Theoria.Validation.IndexedMatchers do
  @moduledoc "Validation helpers for explicit indexed matcher metadata packages."

  alias Theoria.Env
  alias Theoria.Equation.Info
  alias Theoria.Equation.Matcher.Indexed.Package
  alias Theoria.Equation.Matcher.Info, as: MatcherInfo
  alias Theoria.Equation.Matcher.Info.Alternative
  alias Theoria.Equation.Schema
  alias Theoria.Term

  @doc "Builds and validates the validation-only indexed matcher package."
  @spec check(Env.t()) :: {:ok, Package.t()} | {:error, term()}
  def check(%Env{} = env) do
    with {:ok, package} <- Package.build(vec_info(), env),
         :ok <- Package.validate(package) do
      {:ok, package}
    end
  end

  @doc "Returns the validation-only indexed Vec matcher info package."
  @spec vec_info() :: Info.t()
  def vec_info do
    schema =
      Schema.new(:Vec, [],
        recursive_argument: 1,
        parameter_binders: [a: Term.sort(1)],
        argument_binders: [n: Term.const(:Nat), xs: Term.const(:Vec)]
      )

    matcher =
      MatcherInfo.new(:vec_validation_match, 1, 1, [
        %Alternative{constructor: :vec_nil, num_fields: 0},
        %Alternative{constructor: :vec_cons, num_fields: 3}
      ])

    Info.new(:vec_validation_source, Term.const(:Vec), Term.const(:Vec),
      matcher: matcher,
      schema: schema,
      level_params: [:u]
    )
  end
end
