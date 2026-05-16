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

    @type t :: %__MODULE__{level: non_neg_integer()}
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
    defstruct [:name]

    @type t :: %__MODULE__{name: atom()}
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

  @spec sort(non_neg_integer()) :: Sort.t()
  def sort(level) when is_integer(level) and level >= 0, do: %Sort{level: level}

  @spec bvar(non_neg_integer()) :: BVar.t()
  def bvar(index) when is_integer(index) and index >= 0, do: %BVar{index: index}

  @spec const(atom()) :: Const.t()
  def const(name) when is_atom(name), do: %Const{name: name}

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
