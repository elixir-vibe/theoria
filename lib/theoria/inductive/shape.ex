defmodule Theoria.Inductive.Shape do
  @moduledoc "Structured classification of supported inductive shapes."

  alias Theoria.Inductive.Spec
  alias Theoria.Term.{App, Const, Forall}

  @enforce_keys [:kind, :constructors, :parameters]
  defstruct kind: :unknown, constructors: %{}, parameters: []

  @type kind :: :bool_like | :nat_like | :list_like | :unknown
  @type t :: %__MODULE__{
          kind: kind(),
          constructors: map(),
          parameters: list()
        }

  @spec classify(Spec.t() | term()) :: t()
  def classify(%Spec{constructors: constructors, parameters: parameters, name: name}) do
    cond do
      bool = bool_like(constructors, name) ->
        %__MODULE__{kind: :bool_like, constructors: bool, parameters: parameters}

      nat = nat_like(constructors, name) ->
        %__MODULE__{kind: :nat_like, constructors: nat, parameters: parameters}

      list = list_like(constructors, name) ->
        %__MODULE__{kind: :list_like, constructors: list, parameters: parameters}

      true ->
        %__MODULE__{kind: :unknown, constructors: %{}, parameters: parameters}
    end
  end

  def classify(_spec), do: %__MODULE__{kind: :unknown, constructors: %{}, parameters: []}

  defp bool_like([first, second], name) do
    if nullary_constructor?(first.type, name) and nullary_constructor?(second.type, name) do
      %{first: first, second: second}
    end
  end

  defp bool_like(_constructors, _name), do: nil

  defp nat_like([_, _] = constructors, name) do
    zero = Enum.find(constructors, &nullary_constructor?(&1.type, name))
    succ = Enum.find(constructors, &unary_recursive_constructor?(&1.type, name))

    if zero && succ && zero.name != succ.name do
      %{zero: zero, succ: succ}
    end
  end

  defp nat_like(_constructors, _name), do: nil

  defp list_like([_, _] = constructors, name) do
    cons = Enum.find(constructors, &list_cons_constructor?(&1.type, name))

    nil_constructor =
      if cons do
        Enum.find(
          constructors,
          &(constructor_targets_inductive?(&1.type, name) and &1.name != cons.name)
        )
      end

    if nil_constructor && cons do
      %{nil: nil_constructor, cons: cons}
    end
  end

  defp list_like(_constructors, _name), do: nil

  defp nullary_constructor?(%Forall{}, _name), do: false

  defp nullary_constructor?(type, name) do
    constructor_targets_inductive?(type, name) and constructor_argument_types(type, name) == []
  end

  defp unary_recursive_constructor?(%Forall{name: :_, domain: domain, body: body}, name) do
    const_named?(application_head(domain), name) and constructor_targets_inductive?(body, name)
  end

  defp unary_recursive_constructor?(_type, _name), do: false

  defp list_cons_constructor?(%Forall{} = type, name) do
    constructor_targets_inductive?(type, name) and
      Enum.any?(
        constructor_argument_types(type, name),
        &(application_head(&1) |> const_named?(name))
      )
  end

  defp list_cons_constructor?(_type, _name), do: false

  defp constructor_argument_types(type, inductive_name) do
    type
    |> unfold_constructor_arguments(inductive_name)
    |> Enum.map(& &1.domain)
  end

  defp unfold_constructor_arguments(type, inductive_name) do
    Stream.unfold(type, fn
      %Forall{domain: domain, body: body} when not is_struct(body, Forall) ->
        if constructor_targets_inductive?(body, inductive_name) do
          {%{domain: domain}, nil}
        else
          {%{domain: domain}, body}
        end

      %Forall{domain: domain, body: body} ->
        {%{domain: domain}, body}

      _term ->
        nil
    end)
  end

  defp constructor_targets_inductive?(type, inductive_name) do
    match?(%Const{name: ^inductive_name}, application_head(peel_foralls(type)))
  end

  defp peel_foralls(%Forall{body: body}), do: peel_foralls(body)
  defp peel_foralls(type), do: type

  defp application_head(%App{fun: fun}), do: application_head(fun)
  defp application_head(term), do: term

  defp const_named?(%Const{name: name}, name), do: true
  defp const_named?(_term, _name), do: false
end
