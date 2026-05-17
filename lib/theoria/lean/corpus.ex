defmodule Theoria.Lean.Corpus do
  @moduledoc "Collects contributor oracle checks from Theoria theorem modules and fixtures."

  alias Theoria.Elaborator
  alias Theoria.Lean.Module, as: LeanModule
  alias Theoria.Term

  @theorem_modules %{
    equality: Theoria.Library.Equality.Theorems,
    bool: Theoria.Library.Bool.Theorems,
    nat: Theoria.Library.Nat.Theorems,
    list: Theoria.Library.List.Theorems
  }

  @builtin_categories [:equality, :bool, :nat, :list]
  @valid_categories @builtin_categories ++ [:defeq]

  @doc "Returns theorem modules included in the initial Lean oracle corpus."
  @spec builtin_theorem_modules() :: [module()]
  def builtin_theorem_modules,
    do: Enum.map(@builtin_categories, &Map.fetch!(@theorem_modules, &1))

  @doc "Returns valid `--only` corpus categories."
  @spec valid_categories() :: [atom()]
  def valid_categories, do: @valid_categories

  @doc "Builds the initial Lean oracle module."
  @spec build(keyword()) :: {:ok, LeanModule.t(), LeanModule.stats()} | {:error, term()}
  def build(opts \\ []) do
    categories = Keyword.get(opts, :only) || @valid_categories
    theorem_categories = Enum.filter(categories, &(&1 != :defeq))

    with {:ok, module, _proof_count} <-
           add_theorem_modules(LeanModule.new(), theorem_modules(theorem_categories)) do
      module = maybe_add_defeq_fixtures(module, categories)
      {:ok, module, LeanModule.stats(module)}
    end
  end

  defp theorem_modules(categories) do
    Enum.map(categories, &Map.fetch!(@theorem_modules, &1))
  end

  defp add_theorem_modules(module, theorem_modules) do
    Enum.reduce_while(theorem_modules, {:ok, module, 0}, fn theorem_module,
                                                            {:ok, module, count} ->
      case add_theorem_module(module, theorem_module) do
        {:ok, module, added} -> {:cont, {:ok, module, count + added}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp add_theorem_module(module, theorem_module) do
    theorem_module.__theoria_theorems__()
    |> Enum.reduce_while({:ok, module, 0}, fn theorem_name, {:ok, module, count} ->
      with {:ok, type} <-
             theorem_module
             |> apply(String.to_existing_atom("#{theorem_name}_type"), [])
             |> Elaborator.elaborate(),
           {:ok, proof} <-
             theorem_module
             |> apply(String.to_existing_atom("#{theorem_name}_proof"), [])
             |> Elaborator.elaborate() do
        name = "#{inspect(theorem_module)}.#{theorem_name}"
        {:cont, {:ok, LeanModule.add_proof_check(module, name, proof, type), count + 1}}
      else
        {:error, error} -> {:halt, {:error, {theorem_module, theorem_name, error}}}
      end
    end)
  end

  defp maybe_add_defeq_fixtures(module, categories) do
    if :defeq in categories do
      add_defeq_fixtures(module)
    else
      module
    end
  end

  defp add_defeq_fixtures(module) do
    Enum.reduce(defeq_fixtures(), module, fn {_category, name, left, right}, module ->
      LeanModule.add_defeq_check(module, name, left, right)
    end)
  end

  defp defeq_fixtures do
    bool = Term.const(:Bool)
    nat = Term.const(:Nat)
    type = Term.sort(1)
    var = Term.bvar(0)
    bool_true = Term.const(true)
    bool_false = Term.const(false)
    zero = Term.const(:zero)
    succ = Term.const(:succ)
    one = Term.app(succ, zero)
    two = Term.app(succ, one)
    nat_list = Term.app(Term.const(:List), nat)
    nil_nat = Term.app(Term.const(:list_nil), nat)

    singleton_zero =
      Term.const(:list_cons) |> Term.app(nat) |> Term.app(zero) |> Term.app(nil_nat)

    [
      {:defeq, "beta_identity", Term.app(Term.lam(:x, type, var), nat), nat},
      {:defeq, "zeta_identity", Term.let(:x, type, nat, var), nat},
      {:bool, "bool_not_true", Term.app(Term.const(:bool_not), bool_true), bool_false},
      {:bool, "bool_not_false", Term.app(Term.const(:bool_not), bool_false), bool_true},
      {:bool, "bool_and_true_false",
       Term.const(:bool_and) |> Term.app(bool_true) |> Term.app(bool_false), bool_false},
      {:bool, "bool_or_false_true",
       Term.const(:bool_or) |> Term.app(bool_false) |> Term.app(bool_true), bool_true},
      {:bool, "bool_rec_true",
       Term.const(:bool_rec)
       |> Term.app(bool)
       |> Term.app(bool_true)
       |> Term.app(bool_false)
       |> Term.app(bool_true), bool_true},
      {:bool, "bool_rec_false",
       Term.const(:bool_rec)
       |> Term.app(bool)
       |> Term.app(bool_true)
       |> Term.app(bool_false)
       |> Term.app(bool_false), bool_false},
      {:nat, "nat_rec_zero",
       Term.const(:nat_rec)
       |> Term.app(nat)
       |> Term.app(zero)
       |> Term.app(nat_succ_case())
       |> Term.app(zero), zero},
      {:nat, "nat_rec_succ",
       Term.const(:nat_rec)
       |> Term.app(nat)
       |> Term.app(zero)
       |> Term.app(nat_succ_case())
       |> Term.app(one), one},
      {:nat, "nat_add_one_zero", Term.const(:nat_add) |> Term.app(one) |> Term.app(zero), one},
      {:nat, "nat_add_two_zero", Term.const(:nat_add) |> Term.app(two) |> Term.app(zero), two},
      {:list, "list_length_nil", Term.const(:list_length) |> Term.app(nat) |> Term.app(nil_nat),
       zero},
      {:list, "list_length_singleton",
       Term.const(:list_length) |> Term.app(nat) |> Term.app(singleton_zero), one},
      {:list, "list_rec_nil",
       Term.const(:list_rec)
       |> Term.app(nat)
       |> Term.app(nat)
       |> Term.app(zero)
       |> Term.app(list_succ_case(nat_list))
       |> Term.app(nil_nat), zero},
      {:list, "list_rec_cons",
       Term.const(:list_rec)
       |> Term.app(nat)
       |> Term.app(nat)
       |> Term.app(zero)
       |> Term.app(list_succ_case(nat_list))
       |> Term.app(singleton_zero), one}
    ]
  end

  defp list_succ_case(nat_list) do
    Term.lam(
      :_head,
      Term.const(:Nat),
      Term.lam(
        :_tail,
        nat_list,
        Term.lam(:acc, Term.const(:Nat), Term.app(Term.const(:succ), Term.bvar(0)))
      )
    )
  end

  defp nat_succ_case do
    Term.lam(
      :_pred,
      Term.const(:Nat),
      Term.lam(:acc, Term.const(:Nat), Term.app(Term.const(:succ), Term.bvar(0)))
    )
  end
end
