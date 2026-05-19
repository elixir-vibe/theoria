defmodule Theoria.Kernel.Generator do
  @moduledoc """
  Experimental typed term generators for kernel/reference differential assurance.

  The generators return `%Theoria.Kernel.GeneratedTerm{}` values that pair a
  closed term with its expected type and environment. They are deterministic so
  assurance code can use them without depending on test-only property libraries.
  """

  alias Theoria.Kernel.GeneratedTerm
  alias Theoria.Prelude
  alias Theoria.Term

  @spec small_terms(keyword()) :: [GeneratedTerm.t()]
  def small_terms(opts \\ []) do
    size = Keyword.get(opts, :size, 3)
    max_terms = Keyword.get(opts, :max_terms, 128)
    {:ok, env} = Prelude.env()
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)

    bool_terms = bool_terms(size, max_terms: max_terms)
    nat_terms = nat_terms(size, max_terms: max_terms)

    bool_cases = named_cases(:bool, bool_terms, &GeneratedTerm.new(env, &1, bool, &2))
    nat_cases = named_cases(:nat, nat_terms, &GeneratedTerm.new(env, &1, nat, &2))
    equality_cases = named_cases(:nat_refl, nat_terms, &nat_reflexivity_case(env, &1, &2))
    eq_rec_cases = named_cases(:nat_eq_rec, nat_terms, &nat_eq_rec_case(env, &1, &2))
    function_cases = named_cases(:bool_function, bool_terms, &bool_function_case(env, &1, &2))
    let_cases = named_cases(:nat_let, nat_terms, &nat_let_case(env, &1, &2))
    forall_cases = named_cases(:bool_forall, bool_terms, &bool_forall_case(env, &1, &2))

    uniq_generated_terms(
      bool_cases ++
        nat_cases ++
        equality_cases ++
        eq_rec_cases ++
        function_cases ++
        let_cases ++
        forall_cases
    )
  end

  @spec bool_terms(non_neg_integer(), keyword()) :: [Term.t()]
  def bool_terms(size, opts \\ []) do
    size
    |> build_by_size(&bool_layer/2, Keyword.get(opts, :max_terms, 128))
    |> uniq_terms()
  end

  @spec nat_terms(non_neg_integer(), keyword()) :: [Term.t()]
  def nat_terms(size, opts \\ []) do
    size
    |> build_by_size(&nat_layer/2, Keyword.get(opts, :max_terms, 128))
    |> uniq_terms()
  end

  defp build_by_size(size, layer, max_terms) do
    Enum.reduce(0..size//1, [], fn depth, accumulated ->
      layer.(depth, accumulated)
      |> Kernel.++(accumulated)
      |> uniq_terms()
      |> Enum.take(max_terms)
    end)
  end

  defp bool_layer(0, _previous), do: [Term.const(true), Term.const(false)]

  defp bool_layer(_depth, previous) do
    not_terms = Enum.map(previous, &Term.app(Term.const(:bool_not), &1))

    binary_terms =
      binary_applications(Term.const(:bool_and), previous) ++
        binary_applications(Term.const(:bool_or), previous)

    not_terms ++ binary_terms
  end

  defp nat_layer(0, _previous), do: [Term.const(:zero)]

  defp nat_layer(_depth, previous) do
    succ_terms = Enum.map(previous, &Term.app(Term.const(:succ), &1))
    add_terms = binary_applications(Term.const(:nat_add), previous)

    succ_terms ++ add_terms
  end

  defp binary_applications(function, terms) do
    for left <- terms, right <- terms do
      function |> Term.app(left) |> Term.app(right)
    end
  end

  defp named_cases(prefix, terms, callback) do
    terms
    |> Enum.with_index()
    |> Enum.map(fn {term, index} -> callback.(term, {prefix, index}) end)
  end

  defp nat_reflexivity_case(env, term, name) do
    nat = Term.const(:Nat)
    GeneratedTerm.new(env, Term.refl(term), Term.eq(nat, term, term), name)
  end

  defp nat_eq_rec_case(env, term, name) do
    nat = Term.const(:Nat)
    motive = Term.lam(:n, nat, Term.shift(nat, 1))

    GeneratedTerm.new(env, Term.eq_rec(nat, motive, term, Term.refl(term)), nat, name)
  end

  defp bool_function_case(env, term, name) do
    bool = Term.const(:Bool)
    GeneratedTerm.new(env, Term.lam(:x, bool, Term.shift(term, 1)), Term.arrow(bool, bool), name)
  end

  defp nat_let_case(env, term, name) do
    nat = Term.const(:Nat)
    GeneratedTerm.new(env, Term.let(:n, nat, term, Term.bvar(0)), nat, name)
  end

  defp bool_forall_case(env, term, name) do
    bool = Term.const(:Bool)
    body = Term.eq(Term.shift(bool, 1), Term.bvar(0), Term.shift(term, 1))
    GeneratedTerm.new(env, Term.forall(:b, bool, body), Term.sort(0), name)
  end

  defp uniq_generated_terms(terms), do: Enum.uniq_by(terms, &{&1.term, &1.type})
  defp uniq_terms(terms), do: Enum.uniq(terms)
end
