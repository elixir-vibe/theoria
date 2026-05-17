defmodule Theoria.Level do
  @moduledoc "Universe levels."

  alias Theoria.Level.Solver

  import Kernel, except: [max: 2]

  defmodule Zero do
    @moduledoc "The zero universe level."
    defstruct []
    @type t :: %__MODULE__{}
  end

  defmodule Succ do
    @moduledoc "Successor universe level."
    @enforce_keys [:level]
    defstruct [:level]
    @type t :: %__MODULE__{level: Theoria.Level.t()}
  end

  defmodule Max do
    @moduledoc "Maximum of two universe levels."
    @enforce_keys [:left, :right]
    defstruct [:left, :right]
    @type t :: %__MODULE__{left: Theoria.Level.t(), right: Theoria.Level.t()}
  end

  defmodule Param do
    @moduledoc "A universe level parameter."
    @enforce_keys [:name]
    defstruct [:name]
    @type t :: %__MODULE__{name: atom()}
  end

  @type t :: Zero.t() | Succ.t() | Max.t() | Param.t()
  @type subst :: %{optional(atom()) => t()}

  @spec zero() :: Zero.t()
  def zero, do: %Zero{}

  @spec param(atom()) :: Param.t()
  def param(name) when is_atom(name), do: %Param{name: name}

  @spec succ(t()) :: Succ.t()
  def succ(level), do: %Succ{level: level}

  @spec max(t(), t()) :: t()
  def max(left, right), do: normalize(%Max{left: left, right: right})

  @spec cast!(non_neg_integer() | t()) :: t()
  def cast!(level) when is_integer(level) and level >= 0, do: from_integer(level)
  def cast!(%Zero{} = level), do: level
  def cast!(%Succ{} = level), do: level
  def cast!(%Max{} = level), do: level
  def cast!(%Param{} = level), do: level

  @spec from_integer(non_neg_integer()) :: t()
  def from_integer(0), do: zero()

  def from_integer(level) when is_integer(level) and level > 0 do
    level
    |> Kernel.-(1)
    |> from_integer()
    |> succ()
  end

  @spec to_integer(t()) :: {:ok, non_neg_integer()} | :error
  def to_integer(%Zero{}), do: {:ok, 0}

  def to_integer(%Succ{level: level}) do
    case to_integer(level) do
      {:ok, level} -> {:ok, level + 1}
      :error -> :error
    end
  end

  def to_integer(%Max{} = level) do
    case normalize(level) do
      %Max{left: left, right: right} -> max_to_integer(left, right)
      level -> to_integer(level)
    end
  end

  def to_integer(%Param{}), do: :error

  @spec params(t()) :: MapSet.t(atom())
  def params(level), do: collect_params(level, MapSet.new())

  @spec subst(t(), subst()) :: t()
  def subst(%Zero{} = level, _subst), do: level
  def subst(%Param{name: name} = level, subst), do: Map.get(subst, name, level)
  def subst(%Succ{level: level}, subst), do: level |> subst(subst) |> succ() |> normalize()

  def subst(%Max{left: left, right: right}, subst),
    do: max(subst(left, subst), subst(right, subst))

  @spec normalize(t()) :: t()
  def normalize(%Zero{} = level), do: level
  def normalize(%Param{} = level), do: level
  def normalize(%Succ{level: level}), do: %Succ{level: normalize(level)}

  def normalize(%Max{left: left, right: right}) do
    left = normalize(left)
    right = normalize(right)

    cond do
      left == right -> left
      zero?(left) -> right
      zero?(right) -> left
      true -> normalize_closed_max(left, right)
    end
  end

  @spec equal?(t(), t()) :: boolean()
  def equal?(left, right), do: normalize(left) == normalize(right)

  @spec leq?(t(), t()) :: boolean()
  def leq?(left, right), do: Solver.leq?(left, right)

  @spec zero?(t()) :: boolean()
  def zero?(level), do: normalize(level) == zero()

  defp max_to_integer(left, right) do
    case {to_integer(left), to_integer(right)} do
      {{:ok, left}, {:ok, right}} -> {:ok, Kernel.max(left, right)}
      _other -> :error
    end
  end

  defp collect_params(%Zero{}, params), do: params
  defp collect_params(%Param{name: name}, params), do: MapSet.put(params, name)
  defp collect_params(%Succ{level: level}, params), do: collect_params(level, params)

  defp collect_params(%Max{left: left, right: right}, params) do
    left
    |> collect_params(params)
    |> then(&collect_params(right, &1))
  end

  defp normalize_closed_max(left, right) do
    case max_to_integer(left, right) do
      {:ok, level} -> from_integer(level)
      :error -> %Max{left: left, right: right}
    end
  end
end
