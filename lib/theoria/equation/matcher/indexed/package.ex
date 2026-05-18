defmodule Theoria.Equation.Matcher.Indexed.Package do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Coherent package for indexed matcher equation metadata."

  alias Theoria.Env
  alias Theoria.Equation.Info
  alias Theoria.Equation.Matcher.Eqns, as: MatcherEqns
  alias Theoria.Equation.Matcher.Spec, as: MatcherSpec
  alias Theoria.Kernel
  alias Theoria.Term

  @enforce_keys [:info, :env, :matcher, :spec, :equations, :statements, :lemmas]
  defstruct [:info, :env, :matcher, :spec, :equations, :statements, :lemmas]

  @type t :: %__MODULE__{
          info: Info.t(),
          env: Env.t(),
          matcher: Env.Matcher.t(),
          spec: MatcherSpec.t(),
          equations: [Theoria.Equation.Matcher.Equation.t()],
          statements: [Theoria.Equation.Matcher.Equation.t()],
          lemmas: [Theoria.Equation.Lemma.t()]
        }

  @doc "Builds the indexed matcher equation metadata package and admits the explicit matcher into the returned package environment."
  @spec build(Info.t(), Env.t()) :: {:ok, t()} | {:error, term()}
  def build(%Info{} = info, %Env{} = env) do
    with {:ok, spec} <- MatcherSpec.indexed_from_info(info, env: env),
         {:ok, env} <- Kernel.add_matcher(env, spec),
         {:ok, matcher} <- Env.fetch_matcher(env, spec.name),
         {:ok, equations} <- MatcherEqns.indexed_generated(info, env),
         {:ok, statements} <- MatcherEqns.indexed_statements(info, env),
         {:ok, lemmas} <- MatcherEqns.indexed_lemmas(info, env) do
      {:ok,
       %__MODULE__{
         info: info,
         env: env,
         matcher: matcher,
         spec: spec,
         equations: equations,
         statements: statements,
         lemmas: lemmas
       }}
    end
  end

  @doc "Validates the indexed matcher equation package without realizing theorem proofs."
  @spec validate(t()) :: :ok | {:error, term()}
  def validate(%__MODULE__{} = package) do
    with :ok <- validate_matcher(package),
         :ok <- validate_equations(package),
         :ok <- validate_statements(package),
         :ok <- validate_lemmas(package),
         :ok <- validate_realization_boundary(package),
         {:ok, _env} <- Kernel.validate_env(package.env) do
      :ok
    end
  end

  defp validate_matcher(package) do
    cond do
      package.matcher.mode != :indexed_matcher ->
        {:error, {:indexed_matcher_mode_mismatch, package.matcher.name}}

      package.matcher.equation_names != [] ->
        {:error, {:indexed_matcher_equations_installed, package.matcher.name}}

      true ->
        :ok
    end
  end

  defp validate_equations(%__MODULE__{equations: equations, info: %Info{} = info}) do
    constructors = MapSet.new(Enum.map(info.matcher.alternatives, & &1.constructor))

    equations
    |> Enum.reduce_while({:ok, MapSet.new()}, fn equation, {:ok, names} ->
      cond do
        MapSet.member?(names, equation.name) ->
          {:halt, {:error, :duplicate_indexed_matcher_equation_names}}

        equation.matcher != info.matcher.name ->
          {:halt, {:error, :indexed_matcher_equation_matcher_mismatch}}

        not MapSet.member?(constructors, equation.constructor) ->
          {:halt, {:error, {:unknown_indexed_matcher_equation_constructor, equation.constructor}}}

        not equation.indexed? ->
          {:halt, {:error, :non_indexed_matcher_equation}}

        equation.statement_status != :unsupported ->
          {:halt,
           {:error, {:unexpected_indexed_matcher_equation_statement_status, equation.name}}}

        true ->
          {:cont, {:ok, MapSet.put(names, equation.name)}}
      end
    end)
    |> ok_from_accumulator()
  end

  defp validate_statements(%__MODULE__{env: env, statements: statements}) do
    Enum.reduce_while(statements, :ok, fn equation, :ok ->
      case validate_statement(env, equation) do
        :ok -> {:cont, :ok}
        {:error, _reason} = error -> {:halt, error}
      end
    end)
  end

  defp validate_statement(env, equation) do
    cond do
      equation.statement_status != :planned ->
        {:error, {:indexed_matcher_statement_not_planned, equation.name}}

      is_nil(equation.statement_type) ->
        {:error, {:missing_indexed_matcher_statement, equation.name}}

      true ->
        infer_statement_type(env, equation)
    end
  end

  defp infer_statement_type(env, equation) do
    case Kernel.infer(env, equation.statement_type) do
      {:ok, %Term.Sort{}} -> :ok
      {:error, reason} -> {:error, {:indexed_matcher_equation_statement, equation.name, reason}}
    end
  end

  defp validate_lemmas(%__MODULE__{env: env, lemmas: lemmas}) do
    Enum.reduce_while(lemmas, :ok, fn lemma, :ok ->
      case Kernel.infer(env, lemma.equality_type) do
        {:ok, %Term.Sort{}} ->
          {:cont, :ok}

        {:error, reason} ->
          {:halt, {:error, {:indexed_matcher_equation_lemma, lemma.name, reason}}}
      end
    end)
  end

  defp validate_realization_boundary(%__MODULE__{info: info, env: env, equations: equations}) do
    Enum.reduce_while(equations, :ok, fn equation, :ok ->
      case MatcherEqns.indexed_realize(info, env, equation.name) do
        {:error, {:indexed_matcher_equation_not_realized, _name}} -> {:cont, :ok}
        other -> {:halt, {:error, {:indexed_matcher_realization_boundary, equation.name, other}}}
      end
    end)
  end

  defp ok_from_accumulator({:ok, _value}), do: :ok
  defp ok_from_accumulator({:error, _reason} = error), do: error
end
