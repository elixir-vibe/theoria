defmodule Theoria.Kernel.Corpus do
  @moduledoc "Curated kernel terms for production/reference differential checks."

  alias Theoria.Term

  defmodule Summary do
    @moduledoc "Summary counts for the curated kernel corpus."

    @enforce_keys [:infer, :check, :normalize, :defeq, :rejection]
    defstruct [:infer, :check, :normalize, :defeq, :rejection]

    @type t :: %__MODULE__{
            infer: non_neg_integer(),
            check: non_neg_integer(),
            normalize: non_neg_integer(),
            defeq: non_neg_integer(),
            rejection: non_neg_integer()
          }
  end

  @type infer_case :: {atom(), Term.t()}
  @type check_case :: {atom(), Term.t(), Term.t()}
  @type normalize_case :: {atom(), Term.t()}
  @type defeq_case :: {atom(), Term.t(), Term.t()}
  @type infer_rejection_case :: {atom(), Term.t()}
  @type check_rejection_case :: {atom(), Term.t(), Term.t()}

  @doc "Returns summary counts for the curated kernel corpus."
  @spec summary() :: Summary.t()
  def summary do
    %Summary{
      infer: length(infer_cases()),
      check: length(check_cases()),
      normalize: length(normalize_cases()),
      defeq: length(defeq_cases()),
      rejection: length(infer_rejection_cases()) + length(check_rejection_cases())
    }
  end

  @doc "Returns reference-kernel inference cases."
  @spec infer_cases() :: [infer_case()]
  def infer_cases do
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    bool_true = Term.const(true)
    type_zero = Term.sort(0)
    bvar_zero = Term.bvar(0)
    identity_type = Term.forall(:a, type_zero, Term.arrow(bvar_zero, bvar_zero))
    bool_refl = Term.refl(bool_true)
    list_bool = list_bool_example()
    vec_bool = vec_bool_example()

    [
      {:type_zero, type_zero},
      {:bool_constant, bool},
      {:nat_constant, nat},
      {:zero_constructor, zero},
      {:true_constructor, bool_true},
      {:succ_zero, succ(zero)},
      {:bool_not_true, Term.app(Term.const(:bool_not), bool_true)},
      {:identity_type, identity_type},
      {:bool_equality_type, Term.eq(bool, bool_true, bool_true)},
      {:bool_refl, bool_refl},
      {:let_true, Term.let(:b, bool, bool_true, bvar_zero)},
      {:eq_rec_refl, eq_rec_refl(bool, bool_true, bool_refl)},
      {:list_bool_example, list_bool},
      {:vec_bool_example, vec_bool}
    ]
  end

  @doc "Returns reference-kernel checking cases."
  @spec check_cases() :: [check_case()]
  def check_cases do
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)
    zero = Term.const(:zero)
    bool_true = Term.const(true)
    bool_false = Term.const(false)
    bvar_zero = Term.bvar(0)
    bool_refl = Term.refl(bool_true)
    bool_equality = Term.eq(bool, bool_true, bool_true)
    bool_identity = Term.lam(:b, bool, bvar_zero)
    bool_identity_type = Term.arrow(bool, bool)

    [
      {:zero_has_nat, zero, nat},
      {:true_has_bool, bool_true, bool},
      {:false_has_bool, bool_false, bool},
      {:bool_refl_checks, bool_refl, bool_equality},
      {:bool_identity_checks, bool_identity, bool_identity_type},
      {:let_true_checks, Term.let(:b, bool, bool_true, bvar_zero), bool},
      {:eq_rec_refl_checks, eq_rec_refl(bool, bool_true, bool_refl), bool_equality},
      {:list_bool_example_checks, list_bool_example(), list_bool_type()},
      {:vec_bool_example_checks, vec_bool_example(), vec_bool_type(succ(zero))}
    ]
  end

  @doc "Returns rejected inference cases for production/reference comparison."
  @spec infer_rejection_cases() :: [infer_rejection_case()]
  def infer_rejection_cases do
    bool = Term.const(:Bool)
    bool_true = Term.const(true)

    [
      {:unknown_constant, Term.const(:missing_constant)},
      {:unbound_variable, Term.bvar(0)},
      {:not_a_function, Term.app(bool_true, bool_true)},
      {:equality_left_type_mismatch, Term.eq(bool, Term.const(:zero), bool_true)}
    ]
  end

  @doc "Returns rejected checking cases for production/reference comparison."
  @spec check_rejection_cases() :: [check_rejection_case()]
  def check_rejection_cases do
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)
    bool_true = Term.const(true)
    zero = Term.const(:zero)

    [
      {:true_is_not_nat, bool_true, nat},
      {:zero_is_not_bool, zero, bool},
      {:list_nil_is_not_bool, list_nil_bool(), bool},
      {:vec_nil_has_wrong_index, vec_nil_bool(), vec_bool_type(succ(zero))},
      {:refl_true_not_false_equality, Term.refl(bool_true),
       Term.eq(bool, bool_true, Term.const(false))}
    ]
  end

  @doc "Returns normalization cases for production/reference comparison."
  @spec normalize_cases() :: [normalize_case()]
  def normalize_cases do
    bool = Term.const(:Bool)
    bool_true = Term.const(true)
    zero = Term.const(:zero)
    bvar_zero = Term.bvar(0)
    identity = Term.lam(:x, bool, bvar_zero)
    bool_refl = Term.refl(bool_true)
    list_bool = list_bool_example()

    [
      {:beta_identity_true, Term.app(identity, bool_true)},
      {:let_true, Term.let(:b, bool, bool_true, bvar_zero)},
      {:bool_not_true, Term.app(Term.const(:bool_not), bool_true)},
      {:succ_zero, succ(zero)},
      {:eq_rec_refl, eq_rec_refl(bool, bool_true, bool_refl)},
      {:list_length_bool_example,
       Term.app(Term.app(Term.const(:list_length, [1]), bool), list_bool)},
      {:list_append_nil_left,
       Term.app(
         Term.app(Term.app(Term.const(:list_append, [1]), bool), list_nil_bool()),
         list_bool
       )}
    ]
  end

  @doc "Returns defeq cases for production/reference comparison."
  @spec defeq_cases() :: [defeq_case()]
  def defeq_cases do
    bool = Term.const(:Bool)
    bool_true = Term.const(true)
    bool_false = Term.const(false)
    bvar_zero = Term.bvar(0)
    identity = Term.lam(:x, bool, bvar_zero)
    renamed_identity = Term.lam(:y, bool, bvar_zero)
    zero = Term.const(:zero)

    [
      {:beta_identity_true, Term.app(identity, bool_true), bool_true},
      {:let_true, Term.let(:b, bool, bool_true, bvar_zero), bool_true},
      {:bool_not_true, Term.app(Term.const(:bool_not), bool_true), bool_false},
      {:true_not_defeq_false, bool_true, bool_false},
      {:zero_not_defeq_succ_zero, zero, succ(zero)},
      {:list_append_nil_left, list_append_nil_left(list_bool_example()), list_bool_example()},
      {:alpha_equivalent_lambdas, identity, renamed_identity},
      {:alpha_equivalent_foralls, Term.forall(:x, bool, bvar_zero),
       Term.forall(:y, bool, bvar_zero)}
    ]
  end

  defp eq_rec_refl(type, value, proof) do
    motive = Term.lam(:z, type, Term.eq(Term.shift(type, 1), Term.bvar(0), Term.bvar(0)))
    Term.eq_rec(type, motive, Term.refl(value), proof)
  end

  defp list_bool_example do
    list_cons_bool(Term.const(true), list_nil_bool())
  end

  defp list_bool_type do
    Term.app(Term.const(:List, [1]), Term.const(:Bool))
  end

  defp list_nil_bool do
    Term.app(Term.const(:list_nil, [1]), Term.const(:Bool))
  end

  defp list_cons_bool(head, tail) do
    Term.app(Term.app(Term.app(Term.const(:list_cons, [1]), Term.const(:Bool)), head), tail)
  end

  defp list_append_nil_left(term) do
    Term.app(
      Term.app(Term.app(Term.const(:list_append, [1]), Term.const(:Bool)), list_nil_bool()),
      term
    )
  end

  defp vec_bool_example do
    vec_cons_bool(Term.const(true), Term.const(:zero), vec_nil_bool())
  end

  defp vec_bool_type(index) do
    Term.app(Term.app(Term.const(:Vec, [1]), Term.const(:Bool)), index)
  end

  defp vec_nil_bool do
    Term.app(Term.const(:vec_nil, [1]), Term.const(:Bool))
  end

  defp vec_cons_bool(head, index, tail) do
    Term.app(
      Term.app(Term.app(Term.app(Term.const(:vec_cons, [1]), Term.const(:Bool)), head), index),
      tail
    )
  end

  defp succ(term), do: Term.app(Term.const(:succ), term)
end
