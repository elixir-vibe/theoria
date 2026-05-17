defmodule Theoria.Kernel do
  @moduledoc """
  The trusted type-checking kernel.

  The kernel is intentionally small: all DSLs, tactics, and automation must
  reduce to core terms that are accepted here before a theorem is trusted.
  """

  alias Theoria.Context
  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Env.Constructor, as: EnvConstructor
  alias Theoria.Env.Inductive, as: EnvInductive
  alias Theoria.Env.Recursor, as: EnvRecursor
  alias Theoria.Env.RecursorRule
  alias Theoria.Env.Reduction
  alias Theoria.Error
  alias Theoria.Inductive.Admission
  alias Theoria.Inductive.Spec
  alias Theoria.Kernel.TrustReport
  alias Theoria.Normalize
  alias Theoria.Term
  alias Theoria.Term.{App, BVar, Const, Eq, Forall, Lam, Let, Refl, Sort}

  @type result :: {:ok, Term.t()} | {:error, Error.t()}

  def infer(env, term), do: infer(env, Context.new(), term)

  def infer(%Env{} = _env, _context, %Sort{level: level}) do
    {:ok, %Sort{level: Theoria.Level.succ(level)}}
  end

  def infer(%Env{} = _env, %Context{} = context, %BVar{index: index}) do
    case Context.fetch(context, index) do
      {:ok, {_name, type}} -> {:ok, type}
      :error -> error(:unbound_variable, index: index, context_size: Context.size(context))
    end
  end

  def infer(%Env{} = env, _context, %Const{name: name, levels: levels}) do
    case Env.fetch(env, name) do
      {:ok, constant} -> instantiate_constant_type(constant, levels)
      :error -> error(:unknown_constant, name: name)
    end
  end

  def infer(%Env{} = env, %Context{} = context, %App{fun: fun, arg: arg}) do
    with {:ok, fun_type} <- infer(env, context, fun),
         {:ok, fun_type} <- Normalize.whnf(env, fun_type) do
      infer_application_type(env, context, fun_type, arg)
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Lam{name: name, domain: domain, body: body}) do
    with {:ok, %Sort{}} <- infer_sort(env, context, domain),
         extended = Context.push(context, name, domain),
         {:ok, body_type} <- infer(env, extended, body) do
      {:ok, %Forall{name: name, domain: domain, body: body_type}}
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Forall{name: name, domain: domain, body: body}) do
    with {:ok, %Sort{level: domain_level}} <- infer_sort(env, context, domain),
         extended = Context.push(context, name, domain),
         {:ok, %Sort{level: body_level}} <- infer_sort(env, extended, body) do
      {:ok, forall_sort(domain_level, body_level)}
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Let{
        name: name,
        type: type,
        value: value,
        body: body
      }) do
    with {:ok, %Sort{}} <- infer_sort(env, context, type),
         :ok <- check(env, context, value, type),
         extended = Context.push(context, name, type),
         {:ok, body_type} <- infer(env, extended, body) do
      {:ok, Term.subst_top(body_type, value)}
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Eq{type: type, left: left, right: right}) do
    with {:ok, %Sort{}} <- infer_sort(env, context, type),
         :ok <- check(env, context, left, type),
         :ok <- check(env, context, right, type) do
      {:ok, %Sort{level: Theoria.Level.zero()}}
    end
  end

  def infer(%Env{} = env, %Context{} = context, %Refl{value: value}) do
    with {:ok, type} <- infer(env, context, value) do
      {:ok, %Eq{type: type, left: value, right: value}}
    end
  end

  def check(env, term, expected), do: check(env, Context.new(), term, expected)

  def check(%Env{} = env, %Context{} = context, %Lam{} = lam, expected) do
    with {:ok, expected} <- Normalize.whnf(env, expected) do
      check_lambda(env, context, lam, expected)
    end
  end

  def check(%Env{} = env, %Context{} = context, term, expected) do
    case infer(env, context, term) do
      {:ok, actual} -> ensure_defeq(env, actual, expected, :type_mismatch)
      {:error, error} -> {:error, error}
    end
  end

  def add_constant(%Env{} = env, name, type, universe_params \\ [], opts \\ [])
      when is_atom(name) and is_list(universe_params) and is_list(opts) do
    with :ok <- ensure_fresh_declaration(env, name),
         :ok <- ensure_universe_params(universe_params),
         :ok <-
           ensure_constant_kind(
             Keyword.get(opts, :kind, :constant),
             Keyword.get(opts, :metadata),
             Keyword.get(opts, :reduction)
           ),
         :ok <- ensure_reduction(Keyword.get(opts, :reduction)),
         :ok <-
           ensure_reduction_metadata(
             env,
             Keyword.get(opts, :reduction),
             Keyword.get(opts, :metadata)
           ),
         :ok <- ensure_level_params(type, universe_params),
         {:ok, %Sort{}} <- infer_sort(env, Context.new(), type) do
      {:ok, Env.put_constant(env, name, type, universe_params, opts)}
    end
  end

  def add_axiom(%Env{} = env, name, type, universe_params \\ [])
      when is_atom(name) and is_list(universe_params) do
    with :ok <- ensure_fresh_declaration(env, name),
         :ok <- ensure_universe_params(universe_params),
         :ok <- ensure_level_params(type, universe_params),
         {:ok, %Sort{}} <- infer_sort(env, Context.new(), type) do
      {:ok, Env.put_axiom(env, name, type, universe_params)}
    end
  end

  def add_definition(%Env{} = env, name, type, value, universe_params \\ [])
      when is_atom(name) and is_list(universe_params) do
    with :ok <- ensure_fresh_declaration(env, name),
         :ok <- ensure_universe_params(universe_params),
         :ok <- ensure_level_params(type, universe_params),
         :ok <- ensure_level_params(value, universe_params),
         {:ok, %Sort{}} <- infer_sort(env, Context.new(), type),
         :ok <- check(env, Context.new(), value, type) do
      {:ok, Env.put_definition(env, name, type, value, universe_params)}
    end
  end

  def add_theorem(%Env{} = env, name, type, proof, universe_params \\ [])
      when is_atom(name) and is_list(universe_params) do
    with :ok <- ensure_fresh_declaration(env, name),
         :ok <- ensure_universe_params(universe_params),
         :ok <- ensure_level_params(type, universe_params),
         :ok <- ensure_level_params(proof, universe_params),
         {:ok, %Sort{}} <- infer_sort(env, Context.new(), type),
         :ok <- check(env, Context.new(), proof, type) do
      {:ok, Env.put_theorem(env, name, type, proof, universe_params)}
    end
  end

  def add_inductive(%Env{} = env, %Spec{} = spec), do: Admission.install(env, spec)

  def dependencies(%Env{} = env, name) when is_atom(name) do
    case Env.fetch(env, name) do
      {:ok, constant} -> {:ok, declaration_dependencies(constant)}
      :error -> error(:unknown_constant, name: name)
    end
  end

  def transitive_dependencies(%Env{} = env, name) when is_atom(name) do
    with {:ok, _constant} <- fetch_constant(env, name) do
      {:ok, collect_transitive_dependencies(env, [name], MapSet.new())}
    end
  end

  def axioms(%Env{} = env, name) when is_atom(name) do
    with {:ok, dependencies} <- transitive_dependencies(env, name) do
      {:ok, filter_dependencies(env, dependencies, :axiom)}
    end
  end

  def trust_report(%Env{} = env, name) when is_atom(name) do
    with {:ok, constant} <- fetch_constant(env, name),
         {:ok, direct_dependencies} <- dependencies(env, name),
         {:ok, transitive_dependencies} <- transitive_dependencies(env, name),
         {:ok, axioms} <- axioms(env, name) do
      {:ok,
       %TrustReport{
         name: name,
         kind: constant.kind,
         direct_dependencies: direct_dependencies,
         transitive_dependencies: transitive_dependencies,
         axioms: axioms,
         primitive_dependencies: filter_dependencies(env, transitive_dependencies, :constant),
         theorem_dependencies: filter_dependencies(env, transitive_dependencies, :theorem)
       }}
    end
  end

  defp collect_transitive_dependencies(_env, [], seen), do: seen

  defp collect_transitive_dependencies(env, [name | rest], seen) do
    case Env.fetch(env, name) do
      {:ok, constant} ->
        direct = declaration_dependencies(constant)
        new_dependencies = Enum.reject(direct, &MapSet.member?(seen, &1))
        collect_transitive_dependencies(env, new_dependencies ++ rest, MapSet.union(seen, direct))

      :error ->
        collect_transitive_dependencies(env, rest, seen)
    end
  end

  defp filter_dependencies(env, dependencies, kind) do
    dependencies
    |> Enum.filter(&declaration_kind?(env, &1, kind))
    |> MapSet.new()
  end

  defp declaration_kind?(env, name, kind) do
    case Env.fetch(env, name) do
      {:ok, %Constant{kind: ^kind}} -> true
      _other -> false
    end
  end

  defp declaration_dependencies(%Constant{type: type, value: nil}), do: Term.constants(type)

  defp declaration_dependencies(%Constant{type: type, value: value}) do
    MapSet.union(Term.constants(type), Term.constants(value))
  end

  defp fetch_constant(env, name) do
    case Env.fetch(env, name) do
      {:ok, constant} -> {:ok, constant}
      :error -> error(:unknown_constant, name: name)
    end
  end

  defp instantiate_constant_type(%Constant{type: type, universe_params: params}, levels) do
    with :ok <- ensure_universe_arity(params, levels) do
      {:ok, Term.subst_levels(type, Enum.zip(params, levels) |> Map.new())}
    end
  end

  defp ensure_universe_arity(params, levels) do
    if length(params) == length(levels) do
      :ok
    else
      error(:universe_arity_mismatch,
        expected: length(params),
        actual: length(levels),
        params: params
      )
    end
  end

  defp ensure_universe_params(params) do
    cond do
      not Enum.all?(params, &is_atom/1) ->
        error(:invalid_universe_parameters, params: params)

      length(params) != MapSet.size(MapSet.new(params)) ->
        error(:duplicate_universe_parameter, params: params)

      true ->
        :ok
    end
  end

  defp ensure_constant_kind(:constant, nil, nil), do: :ok
  defp ensure_constant_kind(:inductive, %Theoria.Env.Inductive{}, nil), do: :ok
  defp ensure_constant_kind(:constructor, %EnvConstructor{}, nil), do: :ok
  defp ensure_constant_kind(:recursor, %EnvRecursor{}, %Reduction.Iota{}), do: :ok

  defp ensure_constant_kind(_kind, _metadata, _reduction),
    do: error(:invalid_declaration, kind: :metadata)

  defp ensure_reduction(nil), do: :ok

  defp ensure_reduction(reduction) do
    if Reduction.known?(reduction) do
      :ok
    else
      error(:invalid_reduction, reduction: reduction)
    end
  end

  defp ensure_reduction_metadata(_env, nil, _metadata), do: :ok

  defp ensure_reduction_metadata(env, %Reduction.Iota{}, %EnvRecursor{} = recursor) do
    with :ok <- ensure_recursor_rule_count(recursor),
         :ok <- ensure_recursor_rule_coverage(env, recursor),
         :ok <- ensure_recursor_rules(env, recursor) do
      :ok
    else
      {:error, _error} = error -> error
    end
  end

  defp ensure_reduction_metadata(_env, %Reduction.Iota{} = reduction, metadata) do
    error(:invalid_reduction, reduction: reduction, metadata: metadata)
  end

  defp ensure_reduction_metadata(_env, _reduction, _metadata), do: :ok

  defp ensure_recursor_rule_count(%EnvRecursor{} = recursor) do
    if recursor.num_minors == length(recursor.rules) do
      :ok
    else
      error(:invalid_reduction, reduction: %Reduction.Iota{}, metadata: recursor)
    end
  end

  defp ensure_recursor_rule_coverage(env, %EnvRecursor{} = recursor) do
    with {:ok, inductive} <- recursor_inductive(recursor),
         {:ok, %EnvInductive{constructors: constructors}} <- Env.fetch_inductive(env, inductive),
         true <- constructors == Enum.map(recursor.rules, & &1.constructor),
         true <- length(constructors) == MapSet.size(MapSet.new(constructors)) do
      :ok
    else
      _other -> error(:invalid_reduction, reduction: %Reduction.Iota{}, metadata: recursor)
    end
  end

  defp ensure_recursor_rules(env, %EnvRecursor{} = recursor) do
    recursor_env = put_unchecked_recursor(env, recursor)

    if Enum.all?(recursor.rules, &valid_recursor_rule?(recursor_env, recursor, &1)) do
      :ok
    else
      error(:invalid_reduction, reduction: %Reduction.Iota{}, metadata: recursor)
    end
  end

  defp valid_recursor_rule?(env, %EnvRecursor{} = recursor, %RecursorRule{
         constructor: constructor,
         field_count: field_count,
         rhs: rhs
       }) do
    with true <- Term.well_scoped?(rhs),
         true <- MapSet.subset?(Term.level_params(rhs), MapSet.new(recursor.universe_params)),
         true <- inferable_recursor_rule?(env, field_count, rhs),
         {:ok, recursor_inductive} <- recursor_inductive(recursor),
         {:ok, %EnvConstructor{inductive: inductive, num_fields: ^field_count}} <-
           Env.fetch_constructor(env, constructor),
         true <- inductive == recursor_inductive do
      true
    else
      _other -> false
    end
  end

  defp inferable_recursor_rule?(_env, field_count, _rhs) when field_count > 0, do: true

  defp inferable_recursor_rule?(env, _field_count, rhs),
    do: match?({:ok, %Forall{}}, infer(env, rhs))

  defp put_unchecked_recursor(env, %EnvRecursor{} = recursor) do
    Env.put_constant(env, recursor.name, recursor.type, recursor.universe_params,
      kind: :recursor,
      reduction: %Reduction.Iota{},
      metadata: recursor
    )
  end

  defp recursor_inductive(%EnvRecursor{inductives: [inductive]}), do: {:ok, inductive}
  defp recursor_inductive(_recursor), do: :error

  defp ensure_level_params(term, allowed_params) do
    params = Term.level_params(term)
    allowed_params = MapSet.new(allowed_params)

    case MapSet.difference(params, allowed_params) |> MapSet.to_list() do
      [] -> :ok
      params -> error(:unknown_universe_parameter, params: Enum.sort(params))
    end
  end

  def validate_env(%Env{} = env) do
    with :ok <- validate_declaration_index(env) do
      replay_declarations(env)
    end
  end

  defp replay_declarations(env) do
    env
    |> Env.declarations()
    |> Enum.reduce_while({:ok, Env.new()}, &replay_declaration(env, &1, &2))
  end

  defp replay_declaration(env, name, {:ok, checked_env}) do
    case validate_declaration(env, checked_env, name) do
      {:ok, checked_env} -> {:cont, {:ok, checked_env}}
      {:error, error} -> {:halt, {:error, error}}
    end
  end

  defp validate_declaration_index(%Env{constants: constants} = env) do
    declarations = Env.declarations(env)
    declaration_set = MapSet.new(declarations)
    constant_set = constants |> Map.keys() |> MapSet.new()

    cond do
      length(declarations) != MapSet.size(declaration_set) ->
        error(:duplicate_declaration_index, declarations: declarations)

      missing =
          MapSet.difference(declaration_set, constant_set) |> MapSet.to_list() |> List.first() ->
        error(:missing_declaration, name: missing)

      untracked =
          MapSet.difference(constant_set, declaration_set) |> MapSet.to_list() |> List.first() ->
        error(:untracked_declaration, name: untracked)

      true ->
        :ok
    end
  end

  defp validate_declaration(env, checked_env, name) do
    case Env.fetch(env, name) do
      {:ok,
       %Constant{
         kind: kind,
         type: type,
         value: nil,
         universe_params: params,
         reduction: reduction,
         metadata: metadata
       }}
      when kind in [:constant, :inductive, :constructor, :recursor] ->
        add_constant(checked_env, name, type, params,
          kind: kind,
          reduction: reduction,
          metadata: metadata
        )

      {:ok,
       %Constant{kind: :axiom, type: type, value: nil, universe_params: params, reduction: nil}} ->
        add_axiom(checked_env, name, type, params)

      {:ok,
       %Constant{
         kind: :definition,
         type: type,
         value: value,
         universe_params: params,
         reduction: nil
       }}
      when not is_nil(value) ->
        add_definition(checked_env, name, type, value, params)

      {:ok,
       %Constant{
         kind: :theorem,
         type: type,
         value: proof,
         universe_params: params,
         reduction: nil
       }}
      when not is_nil(proof) ->
        add_theorem(checked_env, name, type, proof, params)

      {:ok, _constant} ->
        error(:invalid_declaration, name: name)

      :error ->
        error(:missing_declaration, name: name)
    end
  end

  defp ensure_fresh_declaration(env, name) do
    case Env.fetch(env, name) do
      {:ok, _constant} -> error(:duplicate_declaration, name: name)
      :error -> :ok
    end
  end

  defp check_lambda(env, context, %Lam{} = lam, %Forall{} = expected) do
    with :ok <- ensure_defeq(env, lam.domain, expected.domain, :lambda_domain_mismatch) do
      extended = Context.push(context, lam.name, expected.domain)
      check(env, extended, lam.body, expected.body)
    end
  end

  defp check_lambda(env, context, lam, expected) do
    case infer(env, context, lam) do
      {:ok, actual} -> ensure_defeq(env, actual, expected, :type_mismatch)
      {:error, error} -> {:error, error}
    end
  end

  defp forall_sort(domain_level, body_level) do
    if Theoria.Level.zero?(body_level) do
      %Sort{level: Theoria.Level.zero()}
    else
      %Sort{level: Theoria.Level.max(domain_level, body_level)}
    end
  end

  defp infer_application_type(env, context, %Forall{domain: domain, body: body}, arg) do
    with :ok <- check(env, context, arg, domain) do
      {:ok, Term.subst_top(body, arg)}
    end
  end

  defp infer_application_type(_env, _context, other, _arg) do
    error(:not_a_function, type: other)
  end

  defp infer_sort(env, context, term) do
    with {:ok, type} <- infer(env, context, term),
         {:ok, type} <- Normalize.whnf(env, type) do
      case type do
        %Sort{} -> {:ok, type}
        other -> error(:expected_sort, type: other)
      end
    end
  end

  defp ensure_defeq(env, left, right, reason) do
    if Normalize.defeq?(env, left, right) do
      :ok
    else
      error(reason, left: left, right: right)
    end
  end

  defp error(reason, details), do: {:error, %Error{reason: reason, details: details}}
end
