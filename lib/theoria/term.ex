defmodule Theoria.Term do
  @moduledoc """
  Core terms for Theoria's trusted kernel.

  Terms use de Bruijn indices internally. User-facing names are retained only for
  diagnostics and pretty-printing; binding correctness is determined by indices.
  """

  defmodule Sort do
    @moduledoc "A universe level, written `Type n` in the surface language."
    @enforce_keys [:level]
    defstruct [:level]

    @type t :: %__MODULE__{level: Theoria.Level.t()}
  end

  defmodule BVar do
    @moduledoc "A bound variable represented by a de Bruijn index."
    @enforce_keys [:index]
    defstruct [:index]

    @type t :: %__MODULE__{index: non_neg_integer()}
  end

  defmodule Const do
    @moduledoc "A named environment constant."
    @enforce_keys [:name]
    defstruct [:name, levels: []]

    @type t :: %__MODULE__{name: atom(), levels: [Theoria.Level.t()]}
  end

  defmodule App do
    @moduledoc "Function application."
    @enforce_keys [:fun, :arg]
    defstruct [:fun, :arg]

    @type t :: %__MODULE__{fun: Theoria.Term.t(), arg: Theoria.Term.t()}
  end

  defmodule Lam do
    @moduledoc "Lambda abstraction."
    @enforce_keys [:name, :domain, :body]
    defstruct [:name, :domain, :body]

    @type t :: %__MODULE__{name: atom(), domain: Theoria.Term.t(), body: Theoria.Term.t()}
  end

  defmodule Forall do
    @moduledoc "Dependent function type. Non-dependent functions are encoded as forall types."
    @enforce_keys [:name, :domain, :body]
    defstruct [:name, :domain, :body]

    @type t :: %__MODULE__{name: atom(), domain: Theoria.Term.t(), body: Theoria.Term.t()}
  end

  defmodule Let do
    @moduledoc "Local definition."
    @enforce_keys [:name, :type, :value, :body]
    defstruct [:name, :type, :value, :body]

    @type t :: %__MODULE__{
            name: atom(),
            type: Theoria.Term.t(),
            value: Theoria.Term.t(),
            body: Theoria.Term.t()
          }
  end

  defmodule Eq do
    @moduledoc "Propositional equality over a type."
    @enforce_keys [:type, :left, :right]
    defstruct [:type, :left, :right]

    @type t :: %__MODULE__{
            type: Theoria.Term.t(),
            left: Theoria.Term.t(),
            right: Theoria.Term.t()
          }
  end

  defmodule Refl do
    @moduledoc "Reflexivity proof for propositional equality."
    @enforce_keys [:value]
    defstruct [:value]

    @type t :: %__MODULE__{value: Theoria.Term.t()}
  end

  @type t ::
          Sort.t()
          | BVar.t()
          | Const.t()
          | App.t()
          | Lam.t()
          | Forall.t()
          | Let.t()
          | Eq.t()
          | Refl.t()

  @spec sort(non_neg_integer() | Theoria.Level.t()) :: Sort.t()
  def sort(level), do: %Sort{level: Theoria.Level.cast!(level)}

  @spec bvar(non_neg_integer()) :: BVar.t()
  def bvar(index) when is_integer(index) and index >= 0, do: %BVar{index: index}

  @spec const(atom(), [non_neg_integer() | Theoria.Level.t()]) :: Const.t()
  def const(name, levels \\ []) when is_atom(name) and is_list(levels) do
    %Const{name: name, levels: Enum.map(levels, &Theoria.Level.cast!/1)}
  end

  @spec app(t(), t()) :: App.t()
  def app(fun, arg), do: %App{fun: fun, arg: arg}

  @spec lam(atom(), t(), t()) :: Lam.t()
  def lam(name, domain, body) when is_atom(name), do: %Lam{name: name, domain: domain, body: body}

  @spec forall(atom(), t(), t()) :: Forall.t()
  def forall(name, domain, body) when is_atom(name),
    do: %Forall{name: name, domain: domain, body: body}

  @spec arrow(t(), t()) :: Forall.t()
  def arrow(domain, codomain), do: forall(:_, domain, shift(codomain, 1))

  @spec let(atom(), t(), t(), t()) :: Let.t()
  def let(name, type, value, body) when is_atom(name) do
    %Let{name: name, type: type, value: value, body: body}
  end

  @spec eq(t(), t(), t()) :: Eq.t()
  def eq(type, left, right), do: %Eq{type: type, left: left, right: right}

  @spec refl(t()) :: Refl.t()
  def refl(value), do: %Refl{value: value}

  @doc "Returns the environment constants referenced by `term`."
  @spec constants(t()) :: MapSet.t(atom())
  def constants(term), do: collect_constants(term, MapSet.new())

  @doc "Returns the universe parameters referenced by `term`."
  @spec level_params(t()) :: MapSet.t(atom())
  def level_params(term), do: collect_level_params(term, MapSet.new())

  @doc "Returns true when every bound variable index is in scope at the given depth."
  @spec well_scoped?(t(), non_neg_integer()) :: boolean()
  def well_scoped?(term, depth \\ 0) when is_integer(depth) and depth >= 0 do
    scoped?(term, depth)
  end

  defp collect_constants(%Sort{}, constants), do: constants
  defp collect_constants(%BVar{}, constants), do: constants
  defp collect_constants(%Const{name: name}, constants), do: MapSet.put(constants, name)

  defp collect_constants(%App{fun: fun, arg: arg}, constants) do
    fun
    |> collect_constants(constants)
    |> then(&collect_constants(arg, &1))
  end

  defp collect_constants(%Let{type: type, value: value, body: body}, constants) do
    type
    |> collect_constants(constants)
    |> then(&collect_constants(value, &1))
    |> then(&collect_constants(body, &1))
  end

  defp collect_constants(%Eq{type: type, left: left, right: right}, constants) do
    type
    |> collect_constants(constants)
    |> then(&collect_constants(left, &1))
    |> then(&collect_constants(right, &1))
  end

  defp collect_constants(%Refl{value: value}, constants) do
    collect_constants(value, constants)
  end

  defp collect_constants(%Lam{domain: domain, body: body}, constants) do
    domain
    |> collect_constants(constants)
    |> then(&collect_constants(body, &1))
  end

  defp collect_constants(%Forall{domain: domain, body: body}, constants) do
    domain
    |> collect_constants(constants)
    |> then(&collect_constants(body, &1))
  end

  defp scoped?(%Sort{}, _depth), do: true
  defp scoped?(%Const{}, _depth), do: true
  defp scoped?(%BVar{index: index}, depth), do: index < depth

  defp scoped?(%App{fun: fun, arg: arg}, depth) do
    scoped?(fun, depth) and scoped?(arg, depth)
  end

  defp scoped?(%Lam{domain: domain, body: body}, depth) do
    scoped?(domain, depth) and scoped?(body, depth + 1)
  end

  defp scoped?(%Forall{domain: domain, body: body}, depth) do
    scoped?(domain, depth) and scoped?(body, depth + 1)
  end

  defp scoped?(%Let{type: type, value: value, body: body}, depth) do
    scoped?(type, depth) and scoped?(value, depth) and scoped?(body, depth + 1)
  end

  defp scoped?(%Eq{type: type, left: left, right: right}, depth) do
    scoped?(type, depth) and scoped?(left, depth) and scoped?(right, depth)
  end

  defp scoped?(%Refl{value: value}, depth), do: scoped?(value, depth)

  defp collect_level_params(%Sort{level: level}, params),
    do: MapSet.union(params, Theoria.Level.params(level))

  defp collect_level_params(%Const{levels: levels}, params) do
    Enum.reduce(levels, params, &MapSet.union(&2, Theoria.Level.params(&1)))
  end

  defp collect_level_params(%BVar{}, params), do: params

  defp collect_level_params(%App{fun: fun, arg: arg}, params) do
    fun
    |> collect_level_params(params)
    |> then(&collect_level_params(arg, &1))
  end

  defp collect_level_params(%Let{type: type, value: value, body: body}, params) do
    type
    |> collect_level_params(params)
    |> then(&collect_level_params(value, &1))
    |> then(&collect_level_params(body, &1))
  end

  defp collect_level_params(%Eq{type: type, left: left, right: right}, params) do
    type
    |> collect_level_params(params)
    |> then(&collect_level_params(left, &1))
    |> then(&collect_level_params(right, &1))
  end

  defp collect_level_params(%Refl{value: value}, params), do: collect_level_params(value, params)

  defp collect_level_params(%Lam{domain: domain, body: body}, params) do
    domain
    |> collect_level_params(params)
    |> then(&collect_level_params(body, &1))
  end

  defp collect_level_params(%Forall{domain: domain, body: body}, params) do
    domain
    |> collect_level_params(params)
    |> then(&collect_level_params(body, &1))
  end

  @doc """
  Shifts de Bruijn indices by `amount` at and above `cutoff`.
  """
  @spec shift(t(), integer(), non_neg_integer()) :: t()
  def shift(term, amount, cutoff \\ 0)

  def shift(%Sort{} = term, _amount, _cutoff), do: term
  def shift(%Const{} = term, _amount, _cutoff), do: term

  def shift(%BVar{index: index} = term, amount, cutoff) do
    if index >= cutoff do
      new_index = index + amount

      if new_index < 0 do
        raise ArgumentError, "de Bruijn shift produced a negative index"
      end

      %BVar{term | index: new_index}
    else
      term
    end
  end

  def shift(%App{fun: fun, arg: arg}, amount, cutoff) do
    %App{fun: shift(fun, amount, cutoff), arg: shift(arg, amount, cutoff)}
  end

  def shift(%Let{name: name, type: type, value: value, body: body}, amount, cutoff) do
    %Let{
      name: name,
      type: shift(type, amount, cutoff),
      value: shift(value, amount, cutoff),
      body: shift(body, amount, cutoff + 1)
    }
  end

  def shift(%Eq{type: type, left: left, right: right}, amount, cutoff) do
    %Eq{
      type: shift(type, amount, cutoff),
      left: shift(left, amount, cutoff),
      right: shift(right, amount, cutoff)
    }
  end

  def shift(%Refl{value: value}, amount, cutoff) do
    %Refl{value: shift(value, amount, cutoff)}
  end

  def shift(%Lam{name: name, domain: domain, body: body}, amount, cutoff) do
    %Lam{name: name, domain: shift(domain, amount, cutoff), body: shift(body, amount, cutoff + 1)}
  end

  def shift(%Forall{name: name, domain: domain, body: body}, amount, cutoff) do
    %Forall{
      name: name,
      domain: shift(domain, amount, cutoff),
      body: shift(body, amount, cutoff + 1)
    }
  end

  @doc """
  Substitutes de Bruijn variable `index` with `replacement`.
  """
  @spec subst(t(), non_neg_integer(), t(), non_neg_integer()) :: t()
  def subst(term, index, replacement, depth \\ 0)

  def subst(%Sort{} = term, _index, _replacement, _depth), do: term
  def subst(%Const{} = term, _index, _replacement, _depth), do: term

  def subst(%BVar{index: var_index} = term, index, replacement, depth) do
    if var_index == index + depth do
      shift(replacement, depth)
    else
      term
    end
  end

  def subst(%App{fun: fun, arg: arg}, index, replacement, depth) do
    %App{fun: subst(fun, index, replacement, depth), arg: subst(arg, index, replacement, depth)}
  end

  def subst(%Let{name: name, type: type, value: value, body: body}, index, replacement, depth) do
    %Let{
      name: name,
      type: subst(type, index, replacement, depth),
      value: subst(value, index, replacement, depth),
      body: subst(body, index, replacement, depth + 1)
    }
  end

  def subst(%Eq{type: type, left: left, right: right}, index, replacement, depth) do
    %Eq{
      type: subst(type, index, replacement, depth),
      left: subst(left, index, replacement, depth),
      right: subst(right, index, replacement, depth)
    }
  end

  def subst(%Refl{value: value}, index, replacement, depth) do
    %Refl{value: subst(value, index, replacement, depth)}
  end

  def subst(%Lam{name: name, domain: domain, body: body}, index, replacement, depth) do
    %Lam{
      name: name,
      domain: subst(domain, index, replacement, depth),
      body: subst(body, index, replacement, depth + 1)
    }
  end

  def subst(%Forall{name: name, domain: domain, body: body}, index, replacement, depth) do
    %Forall{
      name: name,
      domain: subst(domain, index, replacement, depth),
      body: subst(body, index, replacement, depth + 1)
    }
  end

  @doc "Substitutes universe level parameters in a term."
  @spec subst_levels(t(), Theoria.Level.subst()) :: t()
  def subst_levels(term, subst)

  def subst_levels(%Sort{level: level}, subst),
    do: %Sort{level: Theoria.Level.subst(level, subst)}

  def subst_levels(%Const{levels: levels} = term, subst) do
    %Const{term | levels: Enum.map(levels, &Theoria.Level.subst(&1, subst))}
  end

  def subst_levels(%BVar{} = term, _subst), do: term

  def subst_levels(%App{fun: fun, arg: arg}, subst) do
    %App{fun: subst_levels(fun, subst), arg: subst_levels(arg, subst)}
  end

  def subst_levels(%Let{name: name, type: type, value: value, body: body}, subst) do
    %Let{
      name: name,
      type: subst_levels(type, subst),
      value: subst_levels(value, subst),
      body: subst_levels(body, subst)
    }
  end

  def subst_levels(%Eq{type: type, left: left, right: right}, subst) do
    %Eq{
      type: subst_levels(type, subst),
      left: subst_levels(left, subst),
      right: subst_levels(right, subst)
    }
  end

  def subst_levels(%Refl{value: value}, subst), do: %Refl{value: subst_levels(value, subst)}

  def subst_levels(%Lam{name: name, domain: domain, body: body}, subst) do
    %Lam{name: name, domain: subst_levels(domain, subst), body: subst_levels(body, subst)}
  end

  def subst_levels(%Forall{name: name, domain: domain, body: body}, subst) do
    %Forall{name: name, domain: subst_levels(domain, subst), body: subst_levels(body, subst)}
  end

  @doc """
  Substitutes the outermost bound variable in `body` with `replacement`.
  """
  @spec subst_top(t(), t()) :: t()
  def subst_top(body, replacement) do
    body
    |> subst(0, shift(replacement, 1))
    |> shift(-1)
  end
end
