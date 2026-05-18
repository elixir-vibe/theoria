defmodule Theoria.Validation do
  @moduledoc "Runs Theoria-owned validation corpora."

  alias Theoria.Env
  alias Theoria.Equation.{Eqns, Extension, Info, Lemma, Schema}
  alias Theoria.Equation.Matcher.Eqns, as: MatcherEqns
  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Equation.Matcher.Info, as: MatcherInfo
  alias Theoria.Equation.Matcher.Info.Alternative
  alias Theoria.Equation.Matcher.Spec, as: MatcherSpec
  alias Theoria.Kernel
  alias Theoria.Prelude
  alias Theoria.Theorem
  alias Theoria.Validation.{Checkable, Corpus, Report}

  @doc "Checks theorem modules, definitional equalities, and inductive specs."
  @spec check(Corpus.t()) :: {:ok, Report.t()} | {:error, term()}
  def check(%Corpus{} = corpus) do
    with {:ok, env} <- Prelude.env(),
         :ok <- check_all(env, corpus.theorem_checks),
         :ok <- check_all(env, corpus.defeq_checks),
         :ok <- check_all(env, corpus.inductive_checks),
         :ok <- check_equation_metadata(env),
         :ok <- check_equation_registry(env),
         {:ok, _env, generated_equations} <- Eqns.install_all(env),
         {:ok, matcher_equation_count} <- check_matcher_equations(env),
         {:ok, indexed_matcher_count} <- check_indexed_matchers(env),
         {:ok, theorem_count, axioms} <- theorem_summary(env, corpus.theorem_modules) do
      {:ok,
       %Report{
         categories: corpus.categories,
         theorem_count: theorem_count,
         defeq_count: length(corpus.defeq_checks),
         inductive_count: length(corpus.inductive_checks),
         equations: Info.all(env),
         generated_equation_count: length(generated_equations),
         matcher_metadata_count: length(Env.matchers(env)),
         indexed_matcher_count: indexed_matcher_count,
         matcher_equation_count: matcher_equation_count,
         axioms: axioms
       }}
    end
  end

  defp check_all(env, checks) do
    Enum.reduce_while(checks, :ok, fn check, :ok ->
      case Checkable.check(check, env) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {check, reason}}}
      end
    end)
  end

  defp check_equation_metadata(env) do
    env
    |> Info.all()
    |> Enum.reduce_while(:ok, fn info, :ok ->
      case validate_equation_info(env, info) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {:equation_metadata, info.name, reason}}}
      end
    end)
  end

  defp validate_equation_info(env, info) do
    case validate_schema_rec_arg(info) do
      :ok -> validate_equation_matcher_metadata(env, info)
      {:error, _reason} = error -> error
    end
  end

  defp validate_equation_matcher_metadata(env, info) do
    with :ok <- validate_matcher_discriminants(info),
         :ok <- validate_fixed_params(info) do
      validate_matcher_sources(env, info)
    end
  end

  defp validate_schema_rec_arg(%Info{schema: nil}), do: :ok

  defp validate_schema_rec_arg(%Info{} = info) do
    if info.rec_arg_pos == info.schema.recursive_argument do
      :ok
    else
      {:error, {:rec_arg_mismatch, info.rec_arg_pos, info.schema.recursive_argument}}
    end
  end

  defp validate_matcher_discriminants(%Info{matcher: nil}), do: :ok

  defp validate_matcher_discriminants(%Info{} = info) do
    if info.matcher.num_discriminants == length(info.matcher.discriminants) do
      :ok
    else
      {:error, {:discriminant_count_mismatch, info.matcher.num_discriminants}}
    end
  end

  defp validate_fixed_params(%Info{schema: nil}), do: :ok

  defp validate_fixed_params(%Info{} = info) do
    parameter_count = length(info.schema.parameter_binders)

    case Enum.find(info.fixed_params.positions, &(&1 < 0 or &1 >= parameter_count)) do
      nil -> :ok
      position -> {:error, {:invalid_fixed_param, position, parameter_count}}
    end
  end

  defp validate_matcher_sources(env, info) do
    info
    |> MatcherEqns.generated()
    |> Enum.reduce_while(:ok, fn equation, :ok ->
      case Eqns.source(env, equation.name) do
        {:ok, source} when source == info.name -> {:cont, :ok}
        other -> {:halt, {:error, {:invalid_matcher_source, equation.name, other}}}
      end
    end)
  end

  defp check_equation_registry(env) do
    with :ok <- check_equation_registry_entries(env) do
      check_equation_registry_realization(env)
    end
  end

  defp check_equation_registry_entries(env) do
    env
    |> Info.all()
    |> Enum.reduce_while(:ok, fn info, :ok ->
      case validate_registry_info(env, info) do
        :ok -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {:equation_registry, info.name, reason}}}
      end
    end)
  end

  defp check_equation_registry_realization(env) do
    case Extension.validate(env) do
      :ok -> :ok
      {:error, reason} -> {:error, {:equation_registry_realization, reason}}
    end
  end

  defp validate_registry_info(env, info) do
    with :ok <- validate_source_matcher(env, info),
         :ok <- validate_ordinary_realization(env, info) do
      validate_matcher_realization(env, info)
    end
  end

  defp validate_source_matcher(_env, %Info{matcher: nil}), do: :ok

  defp validate_source_matcher(env, %Info{} = info) do
    case Env.fetch_matcher(env, info.matcher.name) do
      {:ok, matcher} -> validate_matcher_declaration(info, matcher)
      :error -> {:error, {:missing_matcher, info.matcher.name}}
    end
  end

  defp validate_matcher_declaration(info, matcher) do
    cond do
      matcher.source != info.name ->
        {:error, {:matcher_source_mismatch, matcher.name, matcher.source}}

      matcher.info.name != matcher.name ->
        {:error, {:matcher_info_name_mismatch, matcher.name}}

      not matcher_mode_valid?(info, matcher) ->
        {:error, {:invalid_matcher_mode, matcher.name, matcher.mode}}

      true ->
        :ok
    end
  end

  defp matcher_mode_valid?(info, %{mode: :source_aligned} = matcher) do
    matcher.type == info.type and matcher.value == info.value
  end

  defp matcher_mode_valid?(info, %{mode: :matcher} = matcher) do
    matcher.type != info.type and matcher.value != info.value
  end

  defp validate_ordinary_realization(env, info) do
    info
    |> Lemma.generated_for()
    |> Enum.reduce_while(:ok, fn lemma, :ok ->
      with {:ok, source} <- Extension.source_for(env, lemma.name),
           true <- source == info.name,
           {:ok, _theorem} <- Eqns.realize(env, lemma.name) do
        {:cont, :ok}
      else
        other -> {:halt, {:error, {:ordinary_equation_registry, lemma.name, other}}}
      end
    end)
  end

  defp validate_matcher_realization(env, info) do
    info
    |> MatcherEqns.generated()
    |> Enum.reduce_while(:ok, fn equation, :ok ->
      with {:ok, source} <- MatcherEqns.source(env, equation.name),
           true <- source == equation.matcher,
           {:ok, _theorem} <- MatcherEqns.realize(env, equation.name) do
        {:cont, :ok}
      else
        other -> {:halt, {:error, {:matcher_equation_registry, equation.name, other}}}
      end
    end)
  end

  defp check_matcher_equations(env) do
    env
    |> MatcherEqns.all()
    |> Enum.reduce_while({:ok, 0}, fn %MatcherEquation{} = equation, {:ok, count} ->
      case Lemma.to_theorem(env, MatcherEquation.to_lemma(equation)) do
        {:ok, _theorem} -> {:cont, {:ok, count + 1}}
        {:error, error} -> {:halt, {:error, {:matcher_equation, equation.name, error}}}
      end
    end)
  end

  defp check_indexed_matchers(env) do
    info = indexed_vec_matcher_info()

    with {:ok, spec} <- MatcherSpec.indexed_from_info(info, env: env),
         {:ok, env} <- Kernel.add_matcher(env, spec),
         {:ok, matcher} <- Env.fetch_matcher(env, spec.name),
         :indexed_matcher <- matcher.mode,
         [] <- matcher.equation_names,
         {:ok, _replayed_env} <- Kernel.validate_env(env) do
      {:ok, 1}
    else
      other -> {:error, {:indexed_matcher, other}}
    end
  end

  defp indexed_vec_matcher_info do
    schema =
      Schema.new(:Vec, [],
        recursive_argument: 1,
        parameter_binders: [a: Theoria.Term.sort(1)],
        argument_binders: [n: Theoria.Term.const(:Nat), xs: Theoria.Term.const(:Vec)]
      )

    matcher =
      MatcherInfo.new(:vec_validation_match, 1, 1, [
        %Alternative{constructor: :vec_nil, num_fields: 0},
        %Alternative{constructor: :vec_cons, num_fields: 3}
      ])

    Info.new(:vec_validation_source, Theoria.Term.const(:Vec), Theoria.Term.const(:Vec),
      matcher: matcher,
      schema: schema,
      level_params: [:u]
    )
  end

  defp theorem_summary(env, modules) do
    Enum.reduce_while(modules, {:ok, 0, MapSet.new()}, fn module, {:ok, count, axioms} ->
      case Theorem.check_all(module, env) do
        {:ok, theorems} ->
          {:cont,
           {:ok, count + length(theorems), MapSet.union(axioms, module_axioms(theorems, env))}}

        {:error, error} ->
          {:halt, {:error, {:theorem, module, error}}}
      end
    end)
  end

  defp module_axioms(theorems, env) do
    Enum.reduce(theorems, MapSet.new(), fn theorem, axioms ->
      case Theorem.axioms(env, theorem) do
        {:ok, theorem_axioms} -> MapSet.union(axioms, theorem_axioms)
      end
    end)
  end
end
