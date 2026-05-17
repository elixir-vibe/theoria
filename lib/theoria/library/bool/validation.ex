defmodule Theoria.Library.Bool.Validation do
  @moduledoc "Validation metadata for `Theoria.Library.Bool`."

  alias Theoria.Env
  alias Theoria.Library.Bool
  alias Theoria.Term
  alias Theoria.Validation.{DefeqCheck, InductiveCheck, Library, SmallTerms, TheoremModuleCheck}

  @doc "Returns validation checks owned by the Bool library."
  def checks do
    Library.new(
      TheoremModuleCheck.new(:bool, Bool.Theorems),
      defeq_checks(),
      [InductiveCheck.new(:bool, :Bool, Bool.inductive_spec(), Env.new())]
    )
  end

  defp defeq_checks do
    bool = Term.const(:Bool)
    bool_true = Term.const(true)
    bool_false = Term.const(false)

    [
      DefeqCheck.new(
        :bool,
        "bool_not_true",
        Term.app(Term.const(:bool_not), bool_true),
        bool_false
      ),
      DefeqCheck.new(
        :bool,
        "bool_not_false",
        Term.app(Term.const(:bool_not), bool_false),
        bool_true
      ),
      DefeqCheck.new(
        :bool,
        "bool_and_true_false",
        Term.const(:bool_and) |> Term.app(bool_true) |> Term.app(bool_false),
        bool_false
      ),
      DefeqCheck.new(
        :bool,
        "bool_or_false_true",
        Term.const(:bool_or) |> Term.app(bool_false) |> Term.app(bool_true),
        bool_true
      ),
      DefeqCheck.new(
        :bool,
        "bool_rec_true",
        Term.const(:bool_rec)
        |> Term.app(bool)
        |> Term.app(bool_true)
        |> Term.app(bool_false)
        |> Term.app(bool_true),
        bool_true
      ),
      DefeqCheck.new(
        :bool,
        "bool_rec_false",
        Term.const(:bool_rec)
        |> Term.app(bool)
        |> Term.app(bool_true)
        |> Term.app(bool_false)
        |> Term.app(bool_false),
        bool_false
      )
    ] ++ SmallTerms.defeq_checks(:bool)
  end
end
