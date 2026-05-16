defmodule Theoria.Inductive.Generate do
  @moduledoc "Generators for declarations derived from inductive specs."

  alias Theoria.Env.Reduction
  alias Theoria.Inductive.{Constructor, Recursor, Shape, Spec}
  alias Theoria.Level
  alias Theoria.Syntax, as: S
  alias Theoria.Term.{App, Const}

  import Theoria.DSL, only: [elab!: 1, term: 1]

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
        type: bool_ind_type(spec, on_true.name, on_false.name),
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
        type: nat_ind_type(spec, zero.name, succ.name),
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
        type: list_ind_type(spec, nil_constructor.name, cons.name),
        reduction: recursor_reduction(spec, [nil_constructor, cons])
      }
    ]
  end

  defp constructors(%Shape{kind: kind, constructors: constructors}, kind), do: constructors

  defp recursor_reduction(%Spec{} = spec, constructors) do
    parameter_count = length(spec.parameters)
    branch_start = parameter_count + 1

    %Reduction.Recursor{
      inductive: spec.name,
      major_position: branch_start + length(constructors),
      constructors:
        constructors
        |> Enum.with_index()
        |> Enum.map(fn {constructor, index} ->
          constructor_reduction(spec, constructor, branch_start + index)
        end)
    }
  end

  defp constructor_reduction(%Spec{} = spec, %Constructor{} = constructor, branch_position) do
    {:ok, result} = Constructor.result(constructor, spec)
    parameter_count = length(spec.parameters)
    argument_positions = Enum.to_list(parameter_count..(length(result.binders) - 1)//1)

    %{
      name: constructor.name,
      branch_position: branch_position,
      argument_positions: argument_positions,
      recursive_positions:
        Enum.filter(argument_positions, &recursive_binder?(result, &1, spec.name))
    }
  end

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

  defp bool_ind_type(%Spec{name: name}, true_name, false_name) do
    u = Level.param(:u)
    bool = S.const(name)
    on_true = S.const(true_name)
    on_false = S.const(false_name)

    term do
      forall :motive, ^bool ~> sort(^u) do
        app(motive, ^on_true)
        ~> (app(motive, ^on_false)
            ~> forall :b, ^bool do
              app(motive, b)
            end)
      end
    end
    |> elab!()
  end

  defp nat_ind_type(%Spec{name: name}, zero_name, succ_name) do
    u = Level.param(:u)
    nat = S.const(name)
    zero = S.const(zero_name)
    succ = S.const(succ_name)

    term do
      forall :motive, ^nat ~> sort(^u) do
        app(motive, ^zero)
        ~> (forall :n, ^nat do
              app(motive, n) ~> app(motive, app(^succ, n))
            end
            ~> forall :n, ^nat do
              app(motive, n)
            end)
      end
    end
    |> elab!()
  end

  defp list_ind_type(%Spec{name: name} = spec, nil_name, cons_name) do
    u = Level.param(:u)
    v = Level.param(:v)
    {param_name, param_type, param} = list_parameter(spec)
    list_param = list_type(name, u, param)
    nil_param = S.app(S.const(nil_name, [u]), param)

    cons_param_x_xs =
      S.const(cons_name, [u]) |> S.app(param) |> S.app(S.var(:x)) |> S.app(S.var(:xs))

    term do
      forall ^param_name, ^param_type do
        forall :motive, ^list_param ~> sort(^v) do
          app(motive, ^nil_param)
          ~> (forall :x, ^param do
                forall :xs, ^list_param do
                  app(motive, xs) ~> app(motive, ^cons_param_x_xs)
                end
              end
              ~> forall :xs, ^list_param do
                app(motive, xs)
              end)
        end
      end
    end
    |> elab!()
  end

  defp list_parameter(%Spec{parameters: [%Theoria.Inductive.Parameter{name: name, type: type}]}) do
    {name, syntax_from_core(type), S.var(name)}
  end

  defp list_parameter(%Spec{}) do
    u = Level.param(:u)
    {:a, S.sort(u), S.var(:a)}
  end

  defp syntax_from_core(term, context \\ [])
  defp syntax_from_core(%Theoria.Term.Sort{level: level}, _context), do: S.sort(level)

  defp syntax_from_core(%Theoria.Term.BVar{index: index}, context) do
    context
    |> Enum.fetch!(index)
    |> S.var()
  end

  defp syntax_from_core(%Theoria.Term.Const{name: name, levels: levels}, _context),
    do: S.const(name, levels)

  defp syntax_from_core(%Theoria.Term.App{fun: fun, arg: arg}, context) do
    S.app(syntax_from_core(fun, context), syntax_from_core(arg, context))
  end

  defp list_type(name, level, element) do
    S.app(S.const(name, [level]), element)
  end

  defp base_name(name) do
    name
    |> Atom.to_string()
    |> String.trim_leading("Elixir.")
    |> Macro.underscore()
    |> String.replace("/", "_")
  end
end
