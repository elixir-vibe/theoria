defmodule Theoria.Kernel do
  @moduledoc """
  The trusted type-checking kernel.

  The kernel is intentionally small: all DSLs, tactics, and automation must
  reduce to core terms that are accepted here before a theorem is trusted.
  """

  alias Theoria.Context
  alias Theoria.Env
  alias Theoria.Error
  alias Theoria.Normalize
  alias Theoria.Term
  alias Theoria.Term.{App, BVar, Const, Eq, Forall, Lam, Let, Refl, Sort}

  @type result :: {:ok, Term.t()} | {:error, Error.t()}

  def infer(env, term), do: infer(env, Context.new(), term)

  def infer(%Env{} = _env, _context, %Sort{level: level}) do
    {:ok, %Sort{level: level + 1}}
  end

  def infer(%Env{} = _env, %Context{} = context, %BVar{index: index}) do
    case Context.fetch(context, index) do
      {:ok, {_name, type}} -> {:ok, type}
      :error -> error(:unbound_variable, index: index, context_size: Context.size(context))
    end
  end

  def infer(%Env{} = env, _context, %Const{name: name}) do
    case Env.fetch(env, name) do
      {:ok, constant} -> {:ok, constant.type}
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
      {:ok, %Sort{level: max(domain_level, body_level)}}
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
      {:ok, %Sort{level: 0}}
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

  def add_constant(%Env{} = env, name, type) when is_atom(name) do
    with :ok <- ensure_fresh_declaration(env, name),
         {:ok, %Sort{}} <- infer_sort(env, Context.new(), type) do
      {:ok, Env.put_constant(env, name, type)}
    end
  end

  def add_axiom(%Env{} = env, name, type) when is_atom(name) do
    with :ok <- ensure_fresh_declaration(env, name),
         {:ok, %Sort{}} <- infer_sort(env, Context.new(), type) do
      {:ok, Env.put_axiom(env, name, type)}
    end
  end

  def add_definition(%Env{} = env, name, type, value) when is_atom(name) do
    with :ok <- ensure_fresh_declaration(env, name),
         {:ok, %Sort{}} <- infer_sort(env, Context.new(), type),
         :ok <- check(env, Context.new(), value, type) do
      {:ok, Env.put_definition(env, name, type, value)}
    end
  end

  def add_theorem(%Env{} = env, name, type, proof) when is_atom(name) do
    with :ok <- ensure_fresh_declaration(env, name),
         {:ok, %Sort{}} <- infer_sort(env, Context.new(), type),
         :ok <- check(env, Context.new(), proof, type) do
      {:ok, Env.put_theorem(env, name, type, proof)}
    end
  end

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
      axioms =
        dependencies
        |> Enum.filter(&axiom?(env, &1))
        |> MapSet.new()

      {:ok, axioms}
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

  defp axiom?(env, name) do
    case Env.fetch(env, name) do
      {:ok, %{kind: :axiom}} -> true
      _other -> false
    end
  end

  defp declaration_dependencies(%{type: type, value: nil}), do: Term.constants(type)

  defp declaration_dependencies(%{type: type, value: value}) do
    MapSet.union(Term.constants(type), Term.constants(value))
  end

  defp fetch_constant(env, name) do
    case Env.fetch(env, name) do
      {:ok, constant} -> {:ok, constant}
      :error -> error(:unknown_constant, name: name)
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
      {:ok, %{kind: :constant, type: type}} ->
        add_constant(checked_env, name, type)

      {:ok, %{kind: :axiom, type: type}} ->
        add_axiom(checked_env, name, type)

      {:ok, %{kind: :definition, type: type, value: value}} ->
        add_definition(checked_env, name, type, value)

      {:ok, %{kind: :theorem, type: type, value: proof}} ->
        add_theorem(checked_env, name, type, proof)

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
