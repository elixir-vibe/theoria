defmodule Theoria.Normalize.Primitive do
  @moduledoc "Primitive weak-head reductions for declarations with reduction metadata."

  alias Theoria.Env
  alias Theoria.Env.Constant
  alias Theoria.Env.Reduction
  alias Theoria.Term
  alias Theoria.Term.{App, Const}

  @type fuel :: Theoria.Normalize.Fuel.t()
  @type whnf_result :: {:ok, Term.t(), fuel()} | {:error, Theoria.Error.t()}
  @type whnf_fun :: (Env.t(), Term.t() -> whnf_result())
  @type result :: whnf_result() | {:stuck, App.t()}

  @spec reduce(Env.t(), App.t(), whnf_fun()) :: result()
  def reduce(%Env{} = env, %App{} = app, whnf) when is_function(whnf, 2) do
    case Term.Application.collect(app) do
      {%Const{name: name}, args} -> reduce_constant(env, name, args, app, whnf)
      _other -> {:stuck, app}
    end
  end

  defp reduce_constant(env, name, args, fallback, whnf) do
    case Env.fetch(env, name) do
      {:ok, %Constant{reduction: reduction}} when not is_nil(reduction) ->
        reduce_by_metadata(env, reduction, args, fallback, whnf)

      _other ->
        {:stuck, fallback}
    end
  end

  defp reduce_by_metadata(env, %Reduction.Recursor{} = reduction, args, fallback, whnf) do
    reduce_recursor(env, reduction, args, fallback, whnf)
  end

  defp reduce_by_metadata(env, %Reduction.BoolRec{}, args, fallback, whnf) do
    reduce_recursor(env, bool_recursor(), args, fallback, whnf)
  end

  defp reduce_by_metadata(env, %Reduction.BoolInd{}, args, fallback, whnf) do
    reduce_recursor(env, bool_recursor(), args, fallback, whnf)
  end

  defp reduce_by_metadata(env, %Reduction.NatRec{}, args, fallback, whnf) do
    reduce_recursor(env, nat_recursor(), args, fallback, whnf)
  end

  defp reduce_by_metadata(env, %Reduction.NatInd{}, args, fallback, whnf) do
    reduce_recursor(env, nat_recursor(), args, fallback, whnf)
  end

  defp reduce_by_metadata(env, %Reduction.ListRec{}, args, fallback, whnf) do
    reduce_recursor(env, list_recursor(), args, fallback, whnf)
  end

  defp reduce_by_metadata(env, %Reduction.ListInd{}, args, fallback, whnf) do
    reduce_recursor(env, list_recursor(), args, fallback, whnf)
  end

  defp reduce_recursor(env, %Reduction.Recursor{} = reduction, args, fallback, whnf) do
    with {:ok, major} <- fetch_arg(args, reduction.major_position),
         {%Const{name: constructor}, constructor_args} <- Term.Application.collect(major),
         {:ok, branch} <- constructor_branch(reduction, constructor),
         {:ok, branch_term} <-
           apply_branch(branch, constructor_args, fallback, reduction.major_position) do
      whnf.(env, branch_term)
    else
      _other -> {:stuck, fallback}
    end
  end

  defp constructor_branch(%Reduction.Recursor{constructors: constructors}, name) do
    case Enum.find(constructors, &(&1.name == name)) do
      nil -> :error
      constructor -> {:ok, constructor}
    end
  end

  defp apply_branch(constructor, constructor_args, fallback, major_position) do
    with {:ok, branch} <-
           fetch_arg(Term.Application.collect(fallback) |> elem(1), constructor.branch_position),
         {:ok, direct_args} <-
           select_args(constructor_args, Map.get(constructor, :argument_positions, [])),
         {:ok, recursive_args} <-
           recursive_args(
             constructor_args,
             fallback,
             major_position,
             Map.get(constructor, :recursive_positions, [])
           ) do
      {:ok, Enum.reduce(direct_args ++ recursive_args, branch, &app(&2, &1))}
    end
  end

  defp recursive_args(constructor_args, fallback, major_position, positions) do
    with {:ok, args} <- select_args(constructor_args, positions) do
      {:ok, Enum.map(args, &replace_arg(fallback, major_position, &1))}
    end
  end

  defp select_args(args, positions) do
    Enum.reduce_while(positions, {:ok, []}, fn position, {:ok, selected} ->
      case fetch_arg(args, position) do
        {:ok, arg} -> {:cont, {:ok, [arg | selected]}}
        :error -> {:halt, :error}
      end
    end)
    |> case do
      {:ok, selected} -> {:ok, Enum.reverse(selected)}
      :error -> :error
    end
  end

  defp fetch_arg(args, position) do
    case Enum.fetch(args, position) do
      {:ok, arg} -> {:ok, arg}
      :error -> :error
    end
  end

  defp replace_arg(app, position, replacement) do
    {fun, args} = Term.Application.collect(app)

    args
    |> List.replace_at(position, replacement)
    |> Enum.reduce(fun, &app(&2, &1))
  end

  defp bool_recursor do
    %Reduction.Recursor{
      inductive: :Bool,
      major_position: 3,
      constructors: [
        %{name: true, branch_position: 1, argument_positions: [], recursive_positions: []},
        %{name: false, branch_position: 2, argument_positions: [], recursive_positions: []}
      ]
    }
  end

  defp nat_recursor do
    %Reduction.Recursor{
      inductive: :Nat,
      major_position: 3,
      constructors: [
        %{name: :zero, branch_position: 1, argument_positions: [], recursive_positions: []},
        %{name: :succ, branch_position: 2, argument_positions: [0], recursive_positions: [0]}
      ]
    }
  end

  defp list_recursor do
    %Reduction.Recursor{
      inductive: :List,
      major_position: 4,
      constructors: [
        %{name: :list_nil, branch_position: 2, argument_positions: [], recursive_positions: []},
        %{
          name: :list_cons,
          branch_position: 3,
          argument_positions: [1, 2],
          recursive_positions: [2]
        }
      ]
    }
  end

  defp app(fun, arg), do: %App{fun: fun, arg: arg}
end
