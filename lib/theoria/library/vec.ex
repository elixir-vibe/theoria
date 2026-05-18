defmodule Theoria.Library.Vec do
  @moduledoc "Length-indexed vectors."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Env.Matcher, as: EnvMatcher
  alias Theoria.Equation.Matcher.Indexed.Package, as: IndexedPackage
  alias Theoria.Equation.Matcher.Indexed.Realization, as: IndexedRealization
  alias Theoria.Equation.Matcher.Indexed.Vec, as: IndexedVec
  alias Theoria.Equation.Realized
  alias Theoria.Inductive
  alias Theoria.Inductive.Spec
  alias Theoria.Kernel
  alias Theoria.Level
  alias Theoria.Library.Nat
  alias Theoria.Theorem

  import Theoria.DSL, except: [type: 1]

  @doc "Extends an environment with Vec declarations. Requires Nat declarations."
  @spec extend(Env.t()) :: {:ok, Env.t()} | {:error, Theoria.Error.t()}
  def extend(%Env{} = env) do
    with {:ok, spec} <- Inductive.complete(inductive_spec()) do
      Kernel.add_inductive(env, spec)
    end
  end

  @doc "Returns a new Nat environment extended with Vec declarations."
  @spec env() :: {:ok, Env.t()} | {:error, Theoria.Error.t()}
  def env do
    with {:ok, env} <- Nat.env() do
      extend(env)
    end
  end

  @doc "Extends a Vec environment with the experimental indexed matcher declaration."
  @spec extend_with_indexed_matcher(Env.t(), keyword()) :: {:ok, Env.t()} | {:error, term()}
  def extend_with_indexed_matcher(%Env{} = env, opts \\ []) do
    matcher_name = Keyword.get(opts, :name, :vec_match)

    with {:ok, package} <- IndexedPackage.build(indexed_matcher_info(matcher_name), env),
         :ok <- IndexedPackage.validate(package) do
      maybe_install_indexed_equations(package, opts)
    end
  end

  @doc "Returns a Vec environment extended with the experimental indexed matcher declaration."
  @spec env_with_indexed_matcher(keyword()) :: {:ok, Env.t()} | {:error, term()}
  def env_with_indexed_matcher(opts \\ []) do
    with {:ok, env} <- env() do
      extend_with_indexed_matcher(env, opts)
    end
  end

  @doc "Installs realized equation theorems for an experimental indexed matcher package."
  @spec install_indexed_matcher_equations(IndexedPackage.t()) ::
          {:ok, Env.t(), [Theorem.t()]} | {:error, term()}
  def install_indexed_matcher_equations(%IndexedPackage{} = package) do
    with {:ok, theorems} <- IndexedRealization.realize_all(package),
         {:ok, env, installed} <- install_theorems(package.env, theorems) do
      {:ok, record_indexed_equation_identities(env, package, installed), installed}
    end
  end

  @doc "Returns equation metadata for the experimental Vec indexed matcher declaration."
  @spec indexed_matcher_info(atom()) :: Theoria.Equation.Info.t()
  def indexed_matcher_info(matcher_name \\ :vec_match) when is_atom(matcher_name) do
    IndexedVec.info(matcher_name, :Vec)
  end

  @doc "Returns the inductive specification described by this library."
  @spec inductive_spec() :: Spec.t()
  def inductive_spec do
    u = Level.param(:u)

    :Vec
    |> Spec.new(vec_type(u), universe_params: [:u])
    |> Spec.parameter(:a, term(do: sort(^u)) |> elab!())
    |> Spec.index(:n, term(do: nat()) |> elab!())
    |> Spec.constructor(:vec_nil, vec_nil_type(u))
    |> Spec.constructor(:vec_cons, vec_cons_type(u))
  end

  defp install_theorems(env, theorems) do
    theorems
    |> Enum.reduce_while({:ok, env, []}, &install_theorem/2)
    |> case do
      {:ok, env, installed} -> {:ok, env, Enum.reverse(installed)}
      {:error, _reason} = error -> error
    end
  end

  defp install_theorem(%Realized{} = realized, {:ok, env, installed}) do
    case Realized.install(env, realized) do
      {:ok, env, theorem} -> {:cont, {:ok, env, [theorem | installed]}}
      {:error, _reason} = error -> {:halt, error}
    end
  end

  defp install_theorem(theorem, {:ok, env, installed}) do
    case Theorem.add_to_env(env, theorem) do
      {:ok, env} -> {:cont, {:ok, env, [theorem | installed]}}
      {:error, _reason} = error -> {:halt, error}
    end
  end

  defp record_indexed_equation_identities(%Env{constants: constants} = env, package, theorems) do
    names = Enum.map(theorems, & &1.name)

    constants =
      Map.update!(constants, package.matcher.name, &put_indexed_equation_identities(&1, names))

    %{env | constants: constants}
  end

  defp put_indexed_equation_identities(
         %Constant{metadata: %EnvMatcher{} = matcher} = constant,
         names
       ),
       do: %{constant | metadata: %{matcher | equation_identities: names}}

  defp maybe_install_indexed_equations(package, opts) do
    if Keyword.get(opts, :install_equations, false) do
      with {:ok, env, _theorems} <- install_indexed_matcher_equations(package) do
        {:ok, env}
      end
    else
      {:ok, package.env}
    end
  end

  defp vec_type(u) do
    term do
      forall :a, sort(^u) do
        nat() ~> sort(^u)
      end
    end
    |> elab!()
  end

  defp vec_nil_type(u) do
    term do
      forall :a, sort(^u) do
        app(app(const(:Vec, [^u]), a), zero)
      end
    end
    |> elab!()
  end

  defp vec_cons_type(u) do
    term do
      forall :a, sort(^u) do
        a
        ~> forall :n, nat() do
          app(app(const(:Vec, [^u]), a), n)
          ~> app(app(const(:Vec, [^u]), a), app(succ, n))
        end
      end
    end
    |> elab!()
  end
end
