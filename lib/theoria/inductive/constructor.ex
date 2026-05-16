defmodule Theoria.Inductive.Constructor do
  @moduledoc "Constructor declaration in an inductive specification."

  alias Theoria.Error
  alias Theoria.Inductive.Constructor.Result
  alias Theoria.Inductive.Spec
  alias Theoria.Term
  alias Theoria.Term.{App, Const, Forall}

  @enforce_keys [:name, :type]
  defstruct [:name, :type]

  @type t :: %__MODULE__{name: atom(), type: Term.t()}

  @spec result(t(), Spec.t()) :: {:ok, Result.t()} | {:error, Error.t()}
  def result(%__MODULE__{type: type}, %Spec{name: name} = spec) do
    {binders, target} = collect_binders(type, name, [])
    {head, arguments} = Term.Application.collect(target)
    parameter_count = length(spec.parameters)

    case head do
      %Const{name: ^name} = const ->
        {:ok,
         %Result{
           binders: binders,
           head: const,
           arguments: arguments,
           parameters: Enum.take(arguments, parameter_count),
           indices: Enum.drop(arguments, parameter_count)
         }}

      _other ->
        invalid(:constructor_target_mismatch)
    end
  end

  def result(_constructor, _spec), do: invalid(:invalid_constructor)

  defp collect_binders(%Forall{name: name, domain: domain, body: body}, inductive_name, binders) do
    binder = %{name: name, domain: domain, depth: length(binders)}

    if constructor_result?(body, inductive_name) do
      {Enum.reverse([binder | binders]), body}
    else
      collect_binders(body, inductive_name, [binder | binders])
    end
  end

  defp collect_binders(type, _inductive_name, binders), do: {Enum.reverse(binders), type}

  defp constructor_result?(%Forall{}, _inductive_name), do: false

  defp constructor_result?(type, inductive_name),
    do: application_head(type) == %Const{name: inductive_name}

  defp application_head(%App{fun: fun}), do: application_head(fun)
  defp application_head(term), do: term

  defp invalid(problem) do
    {:error, %Error{reason: :invalid_inductive, details: [problem: problem]}}
  end
end
