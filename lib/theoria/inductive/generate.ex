defmodule Theoria.Inductive.Generate do
  @moduledoc "Generators for declarations derived from inductive specs."

  alias Theoria.Env.Reduction
  alias Theoria.Error
  alias Theoria.Inductive.{Constructor, Recursor, Shape, Spec}
  alias Theoria.Level
  alias Theoria.Syntax, as: S
  alias Theoria.Term
  alias Theoria.Term.{App, Const}

  import Theoria.DSL, only: [elab!: 1]

  @doc "Returns eliminator generation capabilities for an inductive spec."
  @spec capabilities(Spec.t()) :: %{
          supported?: boolean(),
          simple?: boolean(),
          indexed?: boolean(),
          recursive?: boolean(),
          shape: Shape.kind(),
          reason: atom() | nil
        }
  def capabilities(%Spec{} = spec) do
    shape = Shape.classify(spec)
    indexed? = spec.indices != []

    reason =
      cond do
        indexed? -> :indexed_eliminators_unsupported
        shape.kind == :unknown -> :unknown_shape
        not simple_recursive_arguments?(spec) -> :nested_or_unsupported_recursive_argument
        true -> nil
      end

    %{
      supported?: is_nil(reason),
      simple?: is_nil(reason),
      indexed?: indexed?,
      recursive?: recursive?(spec),
      shape: shape.kind,
      reason: reason
    }
  end

  @doc "Returns true when generic eliminator generation supports the spec."
  @spec supported?(Spec.t()) :: boolean()
  def supported?(%Spec{} = spec), do: capabilities(spec).supported?

  @doc "Returns the reason generic eliminator generation does not support the spec."
  @spec unsupported_reason(Spec.t()) :: atom() | nil
  def unsupported_reason(%Spec{} = spec), do: capabilities(spec).reason

  @doc "Generates indexed eliminators with iota rule metadata."
  @spec indexed_eliminators(Spec.t()) :: {:ok, [Recursor.t()]} | {:error, Error.t()}
  def indexed_eliminators(%Spec{indices: []}), do: invalid(:not_indexed)

  def indexed_eliminators(%Spec{} = spec) do
    with {:ok, type} <- indexed_induction_type(spec) do
      {:ok,
       [
         %Recursor{
           name: String.to_atom("#{base_name(spec.name)}_ind"),
           type: type,
           reduction: %Reduction.Iota{}
         }
       ]}
    end
  end

  def indexed_eliminators(_spec), do: invalid(:invalid_spec)

  @doc "Generates the dependent eliminator type for an indexed inductive without iota rules."
  @spec indexed_induction_type(Spec.t()) :: {:ok, Term.t()} | {:error, Error.t()}
  def indexed_induction_type(%Spec{indices: []}), do: invalid(:not_indexed)

  def indexed_induction_type(%Spec{} = spec) do
    if simple_recursive_arguments?(spec) do
      {:ok, indexed_ind_type(spec) |> elab!()}
    else
      invalid(:nested_or_unsupported_recursive_argument)
    end
  end

  def indexed_induction_type(_spec), do: invalid(:invalid_spec)

  @doc "Generates non-dependent and dependent eliminators for supported simple inductives."
  @spec eliminators(Spec.t()) :: {:ok, [Recursor.t()]} | {:error, Error.t()}
  def eliminators(%Spec{} = spec) do
    shape = Shape.classify(spec)

    case capabilities(spec).reason do
      nil -> {:ok, eliminators_for_shape(spec, shape)}
      reason -> invalid(reason)
    end
  end

  def eliminators(_spec), do: invalid(:invalid_spec)

  @doc "Generates eliminators or raises `Theoria.Error`."
  @spec eliminators!(Spec.t()) :: [Recursor.t()]
  def eliminators!(%Spec{} = spec) do
    case eliminators(spec) do
      {:ok, eliminators} -> eliminators
      {:error, error} -> raise error
    end
  end

  @doc "Generates non-dependent and dependent eliminators for a Bool-like inductive."
  @spec bool_eliminators(Spec.t(), Shape.t() | nil) :: [Recursor.t()]
  def bool_eliminators(%Spec{} = spec, shape \\ nil) do
    %{first: on_true, second: on_false} = constructors(shape || Shape.classify(spec), :bool_like)
    base = base_name(spec.name)

    [
      %Recursor{
        name: String.to_atom("#{base}_rec"),
        type: simple_rec_type(spec, [on_true, on_false]),
        reduction: recursor_reduction(spec, [on_true, on_false])
      },
      %Recursor{
        name: String.to_atom("#{base}_ind"),
        type: dependent_ind_type(spec, [on_true, on_false]),
        reduction: recursor_reduction(spec, [on_true, on_false])
      }
    ]
  end

  @doc "Generates non-dependent and dependent eliminators for a Nat-like inductive."
  @spec nat_eliminators(Spec.t(), Shape.t() | nil) :: [Recursor.t()]
  def nat_eliminators(%Spec{} = spec, shape \\ nil) do
    %{zero: zero, succ: succ} = constructors(shape || Shape.classify(spec), :nat_like)
    base = base_name(spec.name)

    [
      %Recursor{
        name: String.to_atom("#{base}_rec"),
        type: simple_rec_type(spec, [zero, succ]),
        reduction: recursor_reduction(spec, [zero, succ])
      },
      %Recursor{
        name: String.to_atom("#{base}_ind"),
        type: dependent_ind_type(spec, [zero, succ]),
        reduction: recursor_reduction(spec, [zero, succ])
      }
    ]
  end

  @doc "Generates non-dependent and dependent eliminators for Theoria's List-like shape."
  @spec list_eliminators(Spec.t(), Shape.t() | nil) :: [Recursor.t()]
  def list_eliminators(%Spec{} = spec, shape \\ nil) do
    %{nil: nil_constructor, cons: cons} = constructors(shape || Shape.classify(spec), :list_like)
    base = base_name(spec.name)

    [
      %Recursor{
        name: String.to_atom("#{base}_rec"),
        type: simple_rec_type(spec, [nil_constructor, cons]),
        reduction: recursor_reduction(spec, [nil_constructor, cons])
      },
      %Recursor{
        name: String.to_atom("#{base}_ind"),
        type: dependent_ind_type(spec, [nil_constructor, cons]),
        reduction: recursor_reduction(spec, [nil_constructor, cons])
      }
    ]
  end

  defp eliminators_for_shape(%Spec{} = spec, %Shape{kind: :bool_like} = shape),
    do: bool_eliminators(spec, shape)

  defp eliminators_for_shape(%Spec{} = spec, %Shape{kind: :nat_like} = shape),
    do: nat_eliminators(spec, shape)

  defp eliminators_for_shape(%Spec{} = spec, %Shape{kind: :list_like} = shape),
    do: list_eliminators(spec, shape)

  defp constructors(%Shape{kind: kind, constructors: constructors}, kind), do: constructors

  defp simple_recursive_arguments?(%Spec{} = spec) do
    Enum.all?(spec.constructors, &simple_recursive_constructor?(&1, spec))
  end

  defp simple_recursive_constructor?(constructor, spec) do
    case Constructor.result(constructor, spec) do
      {:ok, result} -> simple_recursive_result?(result, spec)
      {:error, _error} -> false
    end
  end

  defp simple_recursive_result?(result, spec) do
    result.binders
    |> Enum.drop(length(spec.parameters))
    |> Enum.all?(
      &(not recursive_binder?(result, &1.depth, spec.name) or
          direct_recursive_argument?(&1.domain, spec.name))
    )
  end

  defp recursive?(%Spec{} = spec) do
    Enum.any?(spec.constructors, fn constructor ->
      case Constructor.result(constructor, spec) do
        {:ok, result} ->
          Enum.any?(result.binders, &recursive_binder?(result, &1.depth, spec.name))

        {:error, _error} ->
          false
      end
    end)
  end

  defp direct_recursive_argument?(domain, inductive),
    do: const_named?(application_head(domain), inductive)

  defp invalid(problem),
    do: {:error, %Error{reason: :invalid_inductive, details: [problem: problem]}}

  defp recursor_reduction(%Spec{}, _constructors), do: %Reduction.Iota{}

  defp recursive_binder?(result, position, inductive) do
    result.binders
    |> Enum.at(position)
    |> case do
      %{domain: domain} -> const_named?(application_head(domain), inductive)
      nil -> false
    end
  end

  defp application_head(%App{fun: fun}), do: application_head(fun)
  defp application_head(term), do: term

  defp const_named?(%Const{name: name}, name), do: true
  defp const_named?(_term, _name), do: false

  defp recursor_level(%Spec{universe_params: params}) do
    if :v in params, do: Level.param(:v), else: Level.param(:u)
  end

  defp simple_rec_type(%Spec{} = spec, constructors) do
    v = recursor_level(spec)
    result_name = result_name(spec)
    target = target_type(spec, hd(constructors))

    constructors
    |> Enum.reverse()
    |> Enum.reduce(S.arrow(target, S.var(result_name)), fn constructor, body ->
      S.arrow(branch_type(spec, constructor, result_name), body)
    end)
    |> then(&S.forall(result_name, S.sort(v), &1))
    |> wrap_parameters(spec)
    |> elab!()
  end

  defp target_type(%Spec{} = spec, %Constructor{} = constructor) do
    {:ok, result} = Constructor.result(constructor, spec)

    Enum.reduce(spec.parameters, S.const(spec.name, result.head.levels), fn parameter, target ->
      S.app(target, S.var(parameter.name))
    end)
  end

  defp result_name(%Spec{parameters: []}), do: :a
  defp result_name(%Spec{}), do: :b

  defp branch_type(%Spec{} = spec, %Constructor{} = constructor, result_name) do
    {:ok, result} = Constructor.result(constructor, spec)
    parameter_count = length(spec.parameters)

    result.binders
    |> Enum.drop(parameter_count)
    |> Enum.reverse()
    |> Enum.reduce(S.var(result_name), fn binder, body ->
      domain = syntax_from_core(binder.domain, binder_context(result.binders, binder.depth))

      body =
        if recursive_binder?(result, binder.depth, spec.name),
          do: S.arrow(S.var(result_name), body),
          else: body

      S.arrow(domain, body)
    end)
  end

  defp wrap_parameters(type, %Spec{} = spec) do
    spec.parameters
    |> Enum.reverse()
    |> Enum.reduce(type, fn parameter, body ->
      S.forall(parameter.name, syntax_from_core(parameter.type), body)
    end)
  end

  defp binder_context(binders, depth) do
    binders
    |> Enum.take(depth)
    |> Enum.map(& &1.name)
    |> Enum.reverse()
  end

  defp dependent_ind_type(%Spec{} = spec, constructors) do
    v = recursor_level(spec)
    target = target_type(spec, hd(constructors))

    major_name = major_name(spec)

    constructors
    |> Enum.reverse()
    |> Enum.reduce(major_type(target, major_name), fn constructor, body ->
      S.arrow(dependent_branch_type(spec, constructor), body)
    end)
    |> then(&S.forall(:motive, S.arrow(target, S.sort(v)), &1))
    |> wrap_parameters(spec)
    |> elab!()
  end

  defp major_type(target, name) do
    S.forall(name, target, S.app(S.var(:motive), S.var(name)))
  end

  defp major_name(%Spec{name: :Bool}), do: :b
  defp major_name(%Spec{name: :Nat}), do: :n
  defp major_name(%Spec{name: :List}), do: :xs
  defp major_name(%Spec{}), do: :major

  defp indexed_ind_type(%Spec{} = spec) do
    v = recursor_level(spec)
    target = indexed_target_type(spec)
    major_name = major_name(spec)

    spec.constructors
    |> Enum.reverse()
    |> Enum.reduce(indexed_major_type(spec, target, major_name), fn constructor, body ->
      S.arrow(indexed_branch_type(spec, constructor), body)
    end)
    |> then(&S.forall(:motive, indexed_motive_type(spec, target, v), &1))
    |> wrap_parameters(spec)
  end

  defp indexed_target_type(%Spec{} = spec) do
    parameter_args = Enum.map(spec.parameters, &S.var(&1.name))
    index_args = Enum.map(spec.indices, &S.var(&1.name))

    levels = Enum.map(spec.universe_params, &Level.param/1)

    Enum.reduce(parameter_args ++ index_args, S.const(spec.name, levels), fn arg, fun ->
      S.app(fun, arg)
    end)
  end

  defp indexed_motive_type(%Spec{} = spec, target, level) do
    spec.indices
    |> Enum.reverse()
    |> Enum.reduce(S.arrow(target, S.sort(level)), fn index, body ->
      S.forall(index.name, syntax_from_core(index.type), body)
    end)
  end

  defp indexed_major_type(%Spec{} = spec, target, major_name) do
    major = S.var(major_name)

    motive_app =
      Enum.reduce(
        Enum.map(spec.indices, &S.var(&1.name)) ++ [major],
        S.var(:motive),
        &S.app(&2, &1)
      )

    spec.indices
    |> Enum.reverse()
    |> Enum.reduce(S.forall(major_name, target, motive_app), fn index, body ->
      S.forall(index.name, syntax_from_core(index.type), body)
    end)
  end

  defp indexed_branch_type(%Spec{} = spec, %Constructor{} = constructor) do
    {:ok, result} = Constructor.result(constructor, spec)
    parameter_count = length(spec.parameters)
    argument_binders = argument_binders(result, parameter_count)

    constructor_app =
      constructor_application(constructor, result, spec.parameters, argument_binders)

    motive_app =
      Enum.reduce(
        index_args(result, argument_binders, parameter_count) ++ [constructor_app],
        S.var(:motive),
        &S.app(&2, &1)
      )

    argument_binders
    |> Enum.reverse()
    |> Enum.reduce(motive_app, fn binder, body ->
      body =
        case recursive_indices(
               binder.domain,
               spec,
               indexed_context(result, binder.position, parameter_count)
             ) do
          {:ok, indices} ->
            S.arrow(
              Enum.reduce(indices ++ [S.var(binder.name)], S.var(:motive), &S.app(&2, &1)),
              body
            )

          :error ->
            body
        end

      S.forall(binder.name, syntax_from_core(binder.domain, binder.context), body)
    end)
  end

  defp index_args(result, argument_binders, parameter_count) do
    context =
      argument_binders
      |> Enum.map(& &1.name)
      |> Enum.reverse()
      |> Kernel.++(
        result.binders
        |> Enum.take(parameter_count)
        |> Enum.map(& &1.name)
        |> Enum.reverse()
      )

    Enum.map(result.indices, &syntax_from_core(&1, context))
  end

  defp indexed_context(result, position, parameter_count) do
    fields =
      result.binders
      |> Enum.drop(parameter_count)
      |> Enum.take(position - parameter_count)
      |> Enum.with_index()
      |> Enum.map(fn {binder, index} -> argument_name(binder.name, index) end)
      |> Enum.reverse()

    params = result.binders |> Enum.take(parameter_count) |> Enum.map(& &1.name) |> Enum.reverse()
    fields ++ params
  end

  defp recursive_indices(domain, %Spec{} = spec, context) do
    {head, arguments} = Term.Application.collect(domain)

    case head do
      %Const{name: name} when name == spec.name ->
        {:ok,
         arguments
         |> Enum.drop(length(spec.parameters))
         |> Enum.map(&syntax_from_core(&1, context))}

      _other ->
        :error
    end
  end

  defp dependent_branch_type(%Spec{} = spec, %Constructor{} = constructor) do
    {:ok, result} = Constructor.result(constructor, spec)
    parameter_count = length(spec.parameters)
    argument_binders = argument_binders(result, parameter_count)

    constructor_app =
      constructor_application(constructor, result, spec.parameters, argument_binders)

    argument_binders
    |> Enum.reverse()
    |> Enum.reduce(S.app(S.var(:motive), constructor_app), fn binder, body ->
      body =
        if recursive_binder?(result, binder.position, spec.name),
          do: S.arrow(S.app(S.var(:motive), S.var(binder.name)), body),
          else: body

      S.forall(binder.name, syntax_from_core(binder.domain, binder.context), body)
    end)
  end

  defp argument_binders(result, parameter_count) do
    result.binders
    |> Enum.drop(parameter_count)
    |> Enum.with_index()
    |> Enum.map(fn {binder, index} ->
      name = argument_name(binder.name, index)
      previous_arguments = result.binders |> Enum.drop(parameter_count) |> Enum.take(index)

      context =
        (previous_arguments
         |> Enum.map(&argument_name(&1.name, &1.depth - parameter_count))
         |> Enum.reverse()) ++
          (result.binders |> Enum.take(parameter_count) |> Enum.map(& &1.name) |> Enum.reverse())

      Map.merge(binder, %{name: name, position: binder.depth, context: context})
    end)
  end

  defp argument_name(:_, index), do: String.to_atom("arg#{index}")
  defp argument_name(name, _index), do: name

  defp constructor_application(constructor, result, parameters, argument_binders) do
    parameter_args = Enum.map(parameters, &S.var(&1.name))
    constructor_args = Enum.map(argument_binders, &S.var(&1.name))

    Enum.reduce(
      parameter_args ++ constructor_args,
      S.const(constructor.name, result.head.levels),
      fn arg, fun ->
        S.app(fun, arg)
      end
    )
  end

  defp syntax_from_core(term, context \\ []), do: S.from_core(term, context)

  defp base_name(name) do
    name
    |> Atom.to_string()
    |> String.trim_leading("Elixir.")
    |> Macro.underscore()
    |> String.replace("/", "_")
  end
end
