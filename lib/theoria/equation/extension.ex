defmodule Theoria.Equation.Extension do
  @moduledoc "Experimental/internal API for 0.2; subject to change before 0.3. Typed registry helpers for generated equation and matcher metadata."

  alias Theoria.Env
  alias Theoria.Env.Matcher, as: EnvMatcher
  alias Theoria.Equation.Info
  alias Theoria.Equation.Lemma
  alias Theoria.Equation.Matcher.Eqns, as: MatcherEqns
  alias Theoria.Equation.Matcher.Equation, as: MatcherEquation
  alias Theoria.Equation.Name

  defmodule Registry do
    @moduledoc "In-memory registry snapshot for generated equation metadata."

    alias Theoria.Env.Matcher, as: EnvMatcher
    alias Theoria.Equation.Info

    defstruct definitions: %{},
              matchers: %{},
              matchers_by_source: %{},
              theorem_sources: %{},
              equation_names: %{},
              matcher_equation_names: %{},
              unfold_names: %{}

    @type t :: %__MODULE__{
            definitions: %{optional(atom()) => Info.t()},
            matchers: %{optional(atom()) => EnvMatcher.t()},
            matchers_by_source: %{optional(atom()) => [atom()]},
            theorem_sources: %{optional(atom()) => atom()},
            equation_names: %{optional(atom()) => [atom()]},
            matcher_equation_names: %{optional(atom()) => [atom()]},
            unfold_names: %{optional(atom()) => atom()}
          }
  end

  @doc "Builds an in-memory equation registry snapshot from the environment."
  @spec build(Env.t()) :: Registry.t()
  def build(%Env{} = env) do
    env
    |> definitions()
    |> Enum.reduce(%Registry{}, &register_definition/2)
    |> then(
      &Enum.reduce(matchers(env), &1, fn matcher, registry ->
        register_matcher(env, matcher, registry)
      end)
    )
  end

  @doc "Returns equation definitions known to the registry."
  @spec definitions(Env.t()) :: [Info.t()]
  def definitions(%Env{} = env), do: Info.all(env)

  @doc "Returns matcher declarations known to the registry."
  @spec matchers(Env.t()) :: [EnvMatcher.t()]
  def matchers(%Env{} = env), do: Env.matchers(env)

  @doc "Returns matcher declarations generated for a source definition."
  @spec matchers_for(Env.t(), atom()) :: [EnvMatcher.t()]
  def matchers_for(%Env{} = env, source) when is_atom(source) do
    registry = build(env)

    registry.matchers_by_source
    |> Map.get(source, [])
    |> Enum.flat_map(fn name ->
      case Map.fetch(registry.matchers, name) do
        {:ok, matcher} -> [matcher]
        :error -> []
      end
    end)
  end

  @doc "Returns the source definition or matcher for a generated theorem name."
  @spec source_for(Env.t() | Registry.t(), atom()) :: {:ok, atom()} | :error
  def source_for(env_or_registry, theorem_name)

  def source_for(%Env{} = env, theorem_name) when is_atom(theorem_name) do
    env
    |> build()
    |> source_for(theorem_name)
  end

  def source_for(%Registry{} = registry, theorem_name) when is_atom(theorem_name) do
    case Map.fetch(registry.theorem_sources, theorem_name) do
      {:ok, source} -> {:ok, source}
      :error -> :error
    end
  end

  @doc "Returns all generated theorem identities known to the registry."
  @spec theorem_ids(Env.t() | Registry.t()) :: [Name.t()]
  def theorem_ids(%Env{} = env), do: env |> build() |> theorem_ids()

  def theorem_ids(%Registry{} = registry) do
    registry
    |> theorem_names()
    |> Enum.flat_map(&declaration_id(registry, &1))
  end

  @doc "Returns all generated theorem names known to the registry."
  @spec theorem_names(Env.t() | Registry.t()) :: [atom()]
  def theorem_names(%Env{} = env), do: env |> build() |> theorem_names()

  def theorem_names(%Registry{} = registry) do
    Map.keys(registry.theorem_sources)
  end

  @doc "Returns compact registry counts for diagnostics and validation output."
  @spec summary(Env.t() | Registry.t()) :: map()
  def summary(%Env{} = env), do: env |> build() |> summary()

  def summary(%Registry{} = registry) do
    %{
      definitions: map_size(registry.definitions),
      matchers: map_size(registry.matchers),
      ordinary_equations: count_names(registry.equation_names),
      matcher_equations: count_names(registry.matcher_equation_names),
      unfolds: map_size(registry.unfold_names),
      theorems: map_size(registry.theorem_sources)
    }
  end

  @doc "Validates registry coherence and theorem realization."
  @spec validate(Env.t()) :: :ok | {:error, term()}
  def validate(%Env{} = env) do
    registry = build(env)

    with :ok <- validate_matcher_sources(registry),
         :ok <- validate_matcher_equation_names(env, registry),
         :ok <- validate_source_roundtrip(registry) do
      validate_realization(env, registry)
    end
  end

  @doc "Returns whether a generated theorem can be realized from registry metadata."
  @spec realizable?(Env.t(), atom()) :: boolean()
  def realizable?(%Env{} = env, theorem_name) when is_atom(theorem_name) do
    match?({:ok, _theorem}, realize(env, theorem_name))
  end

  @doc "Realizes any generated ordinary, unfold, or matcher equation theorem without installing it."
  @spec realize(Env.t(), atom()) :: {:ok, Theoria.Theorem.t()} | {:error, term()}
  def realize(%Env{} = env, theorem_name) when is_atom(theorem_name) do
    registry = build(env)

    case source_for(registry, theorem_name) do
      {:ok, source} -> realize_source_theorem(env, registry, source, theorem_name)
      :error -> {:error, {:unknown_generated_theorem, theorem_name}}
    end
  end

  @doc "Realizes every theorem known to the generated equation registry."
  @spec realize_all(Env.t()) :: {:ok, [Theoria.Theorem.t()]} | {:error, term()}
  def realize_all(%Env{} = env) do
    env
    |> theorem_names()
    |> Enum.reduce_while({:ok, []}, fn theorem_name, {:ok, theorems} ->
      case realize(env, theorem_name) do
        {:ok, theorem} -> {:cont, {:ok, [theorem | theorems]}}
        {:error, reason} -> {:halt, {:error, {theorem_name, reason}}}
      end
    end)
    |> case do
      {:ok, theorems} -> {:ok, Enum.reverse(theorems)}
      {:error, _reason} = error -> error
    end
  end

  @doc "Returns generated ordinary equation identities for a source definition."
  @spec equation_ids(Info.t()) :: [Name.t()]
  def equation_ids(%Info{} = info), do: Enum.map(Lemma.generated_for(info), & &1.id)

  @doc "Returns generated ordinary equation identities for a source definition in an environment."
  @spec equation_ids(Env.t(), atom()) :: {:ok, [Name.t()]} | {:error, term()}
  def equation_ids(%Env{} = env, source) when is_atom(source) do
    with {:ok, names} <- equation_names(env, source) do
      {:ok, Enum.flat_map(names, &declaration_id(build(env), &1))}
    end
  end

  @doc "Returns generated ordinary equation names for a source definition."
  @spec equation_names(Info.t()) :: [atom()]
  def equation_names(%Info{} = info), do: Enum.map(Lemma.generated_for(info), & &1.name)

  @doc "Returns generated ordinary equation names for a source definition in an environment."
  @spec equation_names(Env.t(), atom()) :: {:ok, [atom()]} | {:error, term()}
  def equation_names(%Env{} = env, source) when is_atom(source) do
    case Map.fetch(build(env).equation_names, source) do
      {:ok, names} -> {:ok, names}
      :error -> {:error, {:unknown_equation_definition, source}}
    end
  end

  @doc "Returns generated matcher equation identities for a matcher declaration."
  @spec matcher_equation_ids(Env.t(), EnvMatcher.t()) :: [Name.t()]
  def matcher_equation_ids(%Env{} = env, %EnvMatcher{} = matcher) do
    env
    |> matcher_equations_for(matcher)
    |> Enum.map(& &1.id)
  end

  @doc "Returns generated matcher equation names for a matcher declaration."
  @spec matcher_equation_names(Env.t(), EnvMatcher.t()) :: [atom()]
  def matcher_equation_names(%Env{} = env, %EnvMatcher{} = matcher) do
    env
    |> matcher_equations_for(matcher)
    |> Enum.map(& &1.name)
  end

  @doc "Returns the unfold theorem identity for a source definition."
  @spec unfold_id(Env.t(), atom()) :: {:ok, Name.t()} | {:error, term()}
  def unfold_id(%Env{} = env, source) when is_atom(source) do
    with {:ok, name} <- unfold_name(env, source) do
      case declaration_id(build(env), name) do
        [id] -> {:ok, id}
        [] -> {:error, {:unknown_equation_definition, source}}
      end
    end
  end

  @doc "Returns the unfold theorem name for a source definition."
  @spec unfold_name(Env.t(), atom()) :: {:ok, atom()} | {:error, term()}
  def unfold_name(%Env{} = env, source) when is_atom(source) do
    case Map.fetch(build(env).unfold_names, source) do
      {:ok, name} -> {:ok, name}
      :error -> {:error, {:unknown_equation_definition, source}}
    end
  end

  defp declaration_id(%Registry{} = registry, theorem_name) do
    case source_for(registry, theorem_name) do
      {:ok, source} ->
        registry
        |> source_equation_ids(source)
        |> Enum.filter(&(Name.to_declaration(&1) == theorem_name))

      :error ->
        []
    end
  end

  defp source_equation_ids(%Registry{} = registry, source) do
    cond do
      info = Map.get(registry.definitions, source) ->
        [Lemma.unfold_for(info).id | equation_ids(info)]

      matcher = Map.get(registry.matchers, source) ->
        matcher_equation_ids_from_names(registry, matcher)

      true ->
        []
    end
  end

  defp matcher_equation_ids_from_names(%Registry{} = registry, %EnvMatcher{} = matcher) do
    registry.matcher_equation_names
    |> Map.get(matcher.name, [])
    |> Enum.map(&matcher_equation_id(matcher, &1))
  end

  defp matcher_equation_id(%EnvMatcher{mode: :indexed_matcher, name: matcher}, name),
    do: Name.indexed_matcher_equation(matcher, matcher_equation_target(name))

  defp matcher_equation_id(%EnvMatcher{name: matcher}, name),
    do: Name.matcher_equation(matcher, matcher_equation_target(name))

  defp matcher_equation_target(name) do
    name
    |> Atom.to_string()
    |> String.split("__")
    |> List.last()
    |> String.to_atom()
  end

  defp matcher_equations_for(
         _env,
         %EnvMatcher{mode: :indexed_matcher, equation_names: names} = matcher
       )
       when names != [] do
    Enum.map(names, fn name ->
      %MatcherEquation{
        matcher: matcher.name,
        id: matcher_equation_id(matcher, name),
        name: name,
        constructor: matcher_equation_target(name),
        left: nil,
        right: nil,
        equality_type: nil,
        indexed?: true
      }
    end)
  end

  defp matcher_equations_for(env, matcher) do
    case MatcherEqns.generated(env, matcher.name) do
      {:ok, equations} -> equations
      {:error, _reason} -> []
    end
  end

  defp count_names(names_by_source) do
    Enum.reduce(names_by_source, 0, fn {_source, names}, count -> count + length(names) end)
  end

  defp validate_matcher_sources(%Registry{} = registry) do
    registry.matchers
    |> Enum.reduce_while(:ok, fn {_name, matcher}, :ok ->
      if Map.has_key?(registry.definitions, matcher.source) do
        {:cont, :ok}
      else
        {:halt, {:error, {:unknown_matcher_source, matcher.name, matcher.source}}}
      end
    end)
  end

  defp validate_matcher_equation_names(env, %Registry{} = registry) do
    registry.matchers
    |> Enum.reduce_while(:ok, fn {_name, matcher}, :ok ->
      names = Map.get(registry.matcher_equation_names, matcher.name, [])

      if matcher.equation_names == names do
        {:cont, :ok}
      else
        {:halt,
         {:error, {:matcher_equation_name_mismatch, matcher.name, matcher.equation_names, names}}}
      end
    end)
    |> case do
      :ok -> validate_matcher_name_generation(env, registry)
      {:error, _reason} = error -> error
    end
  end

  defp validate_matcher_name_generation(env, %Registry{} = registry) do
    registry.matchers
    |> Enum.reduce_while(:ok, fn {_name, matcher}, :ok ->
      generated = matcher_equation_names(env, matcher)
      names = Map.get(registry.matcher_equation_names, matcher.name, [])

      if generated == names do
        {:cont, :ok}
      else
        {:halt, {:error, {:matcher_generated_name_mismatch, matcher.name, generated, names}}}
      end
    end)
  end

  defp validate_source_roundtrip(%Registry{} = registry) do
    registry.theorem_sources
    |> Enum.reduce_while(:ok, fn {theorem_name, source}, :ok ->
      case source_for(registry, theorem_name) do
        {:ok, ^source} -> {:cont, :ok}
        other -> {:halt, {:error, {:source_roundtrip_failed, theorem_name, source, other}}}
      end
    end)
  end

  defp validate_realization(env, %Registry{} = registry) do
    registry
    |> theorem_names()
    |> Enum.reduce_while(:ok, fn theorem_name, :ok ->
      case realize(env, theorem_name) do
        {:ok, _theorem} -> {:cont, :ok}
        {:error, reason} -> {:halt, {:error, {:realization_failed, theorem_name, reason}}}
      end
    end)
  end

  defp realize_source_theorem(env, %Registry{} = registry, source, theorem_name) do
    cond do
      info = Map.get(registry.definitions, source) ->
        realize_definition_theorem(env, info, theorem_name)

      matcher = Map.get(registry.matchers, source) ->
        realize_matcher_theorem(env, matcher, theorem_name)

      true ->
        {:error, {:unknown_generated_source, source}}
    end
  end

  defp realize_definition_theorem(env, %Info{} = info, theorem_name) do
    unfold = Lemma.unfold_for(info)

    cond do
      unfold.name == theorem_name ->
        Lemma.to_theorem(env, unfold)

      lemma = Enum.find(Lemma.generated_for(info), &(&1.name == theorem_name)) ->
        Lemma.to_theorem(env, lemma)

      true ->
        {:error, {:unknown_equation_for_source, info.name, theorem_name}}
    end
  end

  defp realize_matcher_theorem(env, %EnvMatcher{} = matcher, theorem_name) do
    env
    |> MatcherEqns.all()
    |> Enum.find_value(
      {:error, {:unknown_matcher_equation, matcher.name, theorem_name}},
      fn equation ->
        if equation.name == theorem_name and equation.matcher == matcher.name do
          equation
          |> MatcherEquation.to_lemma()
          |> then(&Lemma.to_theorem(env, &1))
        else
          false
        end
      end
    )
  end

  defp register_definition(%Info{} = info, %Registry{} = registry) do
    equations = equation_names(info)
    unfold = Lemma.unfold_for(info).name

    %Registry{
      registry
      | definitions: Map.put(registry.definitions, info.name, info),
        equation_names: Map.put(registry.equation_names, info.name, equations),
        unfold_names: Map.put(registry.unfold_names, info.name, unfold),
        theorem_sources:
          registry.theorem_sources
          |> put_sources(info.name, equations)
          |> Map.put(unfold, info.name)
    }
  end

  defp register_matcher(env, %EnvMatcher{} = matcher, %Registry{} = registry) do
    equations = matcher_equation_names(env, matcher)

    %Registry{
      registry
      | matchers: Map.put(registry.matchers, matcher.name, matcher),
        matchers_by_source:
          Map.update(
            registry.matchers_by_source,
            matcher.source,
            [matcher.name],
            &(&1 ++ [matcher.name])
          ),
        matcher_equation_names: Map.put(registry.matcher_equation_names, matcher.name, equations),
        theorem_sources: put_sources(registry.theorem_sources, matcher.name, equations)
    }
  end

  defp put_sources(sources, source, names) do
    Enum.reduce(names, sources, fn name, sources -> Map.put(sources, name, source) end)
  end
end
