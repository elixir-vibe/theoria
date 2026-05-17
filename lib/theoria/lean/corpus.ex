defmodule Theoria.Lean.Corpus do
  @moduledoc "Collects contributor oracle checks from Theoria theorem modules and fixtures."

  alias Theoria.Elaborator
  alias Theoria.Lean.Module, as: LeanModule
  alias Theoria.Term

  @builtin_theorem_modules [
    Theoria.Library.Equality.Theorems,
    Theoria.Library.Bool.Theorems,
    Theoria.Library.Nat.Theorems
  ]

  @doc "Returns theorem modules included in the initial Lean oracle corpus."
  @spec builtin_theorem_modules() :: [module()]
  def builtin_theorem_modules, do: @builtin_theorem_modules

  @doc "Builds the initial Lean oracle module."
  @spec build() :: {:ok, LeanModule.t(), LeanModule.stats()} | {:error, term()}
  def build do
    with {:ok, module, _proof_count} <-
           add_theorem_modules(LeanModule.new(), @builtin_theorem_modules) do
      module = add_defeq_fixtures(module)
      {:ok, module, LeanModule.stats(module)}
    end
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

  defp add_defeq_fixtures(module) do
    Enum.reduce(defeq_fixtures(), module, fn {name, left, right}, module ->
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

    [
      {"beta_identity", Term.app(Term.lam(:x, type, var), nat), nat},
      {"zeta_identity", Term.let(:x, type, nat, var), nat},
      {"bool_not_true", Term.app(Term.const(:bool_not), bool_true), bool_false},
      {"bool_not_false", Term.app(Term.const(:bool_not), bool_false), bool_true},
      {"bool_and_true_false",
       Term.const(:bool_and) |> Term.app(bool_true) |> Term.app(bool_false), bool_false},
      {"bool_or_false_true", Term.const(:bool_or) |> Term.app(bool_false) |> Term.app(bool_true),
       bool_true},
      {"bool_rec_true",
       Term.const(:bool_rec)
       |> Term.app(bool)
       |> Term.app(bool_true)
       |> Term.app(bool_false)
       |> Term.app(bool_true), bool_true},
      {"bool_rec_false",
       Term.const(:bool_rec)
       |> Term.app(bool)
       |> Term.app(bool_true)
       |> Term.app(bool_false)
       |> Term.app(bool_false), bool_false},
      {"nat_rec_zero",
       Term.const(:nat_rec)
       |> Term.app(nat)
       |> Term.app(zero)
       |> Term.app(succ_case())
       |> Term.app(zero), zero},
      {"nat_rec_succ",
       Term.const(:nat_rec)
       |> Term.app(nat)
       |> Term.app(zero)
       |> Term.app(succ_case())
       |> Term.app(one), one},
      {"nat_add_one_zero", Term.const(:nat_add) |> Term.app(one) |> Term.app(zero), one},
      {"nat_add_two_zero", Term.const(:nat_add) |> Term.app(two) |> Term.app(zero), two}
    ]
  end

  defp succ_case do
    Term.lam(
      :_pred,
      Term.const(:Nat),
      Term.lam(:acc, Term.const(:Nat), Term.app(Term.const(:succ), Term.bvar(0)))
    )
  end
end
