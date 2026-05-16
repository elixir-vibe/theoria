defmodule Theoria.Level do
  @moduledoc "Universe levels."

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

  @type t :: Zero.t() | Succ.t() | Max.t()

  @spec zero() :: Zero.t()
  def zero, do: %Zero{}

  @spec succ(t()) :: Succ.t()
  def succ(level), do: %Succ{level: level}

  @spec max(t(), t()) :: t()
  def max(left, right) do
    {:ok, left} = to_integer(left)
    {:ok, right} = to_integer(right)
    from_integer(Kernel.max(left, right))
  end

  @spec cast!(non_neg_integer() | t()) :: t()
  def cast!(level) when is_integer(level) and level >= 0, do: from_integer(level)
  def cast!(%Zero{} = level), do: level
  def cast!(%Succ{} = level), do: level
  def cast!(%Max{} = level), do: level

  @spec from_integer(non_neg_integer()) :: t()
  def from_integer(0), do: zero()

  def from_integer(level) when is_integer(level) and level > 0 do
    level
    |> Kernel.-(1)
    |> from_integer()
    |> succ()
  end

  @spec to_integer(t()) :: {:ok, non_neg_integer()}
  def to_integer(%Zero{}), do: {:ok, 0}

  def to_integer(%Succ{level: level}) do
    {:ok, level} = to_integer(level)
    {:ok, level + 1}
  end

  def to_integer(%Max{left: left, right: right}) do
    {:ok, left} = to_integer(left)
    {:ok, right} = to_integer(right)
    {:ok, Kernel.max(left, right)}
  end

  @spec zero?(t()) :: boolean()
  def zero?(%Zero{}), do: true
  def zero?(_level), do: false
end
