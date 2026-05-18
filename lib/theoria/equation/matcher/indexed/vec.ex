defmodule Theoria.Equation.Matcher.Indexed.Vec do
  @moduledoc "Experimental/internal API for indexed Vec matcher metadata packages."

  alias Theoria.Equation.Info
  alias Theoria.Equation.Matcher.Info, as: MatcherInfo
  alias Theoria.Equation.Matcher.Info.Alternative
  alias Theoria.Equation.Schema
  alias Theoria.Term

  @doc "Returns equation metadata for an indexed Vec matcher declaration."
  @spec info(atom(), atom()) :: Info.t()
  def info(matcher_name \\ :vec_match, source_name \\ :Vec)
      when is_atom(matcher_name) and is_atom(source_name) do
    schema =
      Schema.new(:Vec, [],
        recursive_argument: 1,
        parameter_binders: [a: Term.sort(1)],
        argument_binders: [n: Term.const(:Nat), xs: Term.const(:Vec)]
      )

    matcher =
      MatcherInfo.new(matcher_name, 1, 1, [
        %Alternative{constructor: :vec_nil, num_fields: 0},
        %Alternative{constructor: :vec_cons, num_fields: 3}
      ])

    Info.new(source_name, Term.const(:Vec), Term.const(:Vec),
      matcher: matcher,
      schema: schema,
      level_params: [:u]
    )
  end
end
