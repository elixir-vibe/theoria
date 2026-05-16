defmodule Theoria.Env.Reduction do
  @moduledoc "Primitive reduction metadata attached to environment declarations."

  defmodule Recursor do
    @moduledoc "Generic reduction metadata for constructor-recursion eliminators."
    @enforce_keys [:inductive, :major_position, :constructors]
    defstruct [:inductive, :major_position, constructors: []]

    @type constructor :: %{
            required(:name) => atom(),
            required(:branch_position) => non_neg_integer(),
            optional(:argument_positions) => [non_neg_integer()],
            optional(:recursive_positions) => [non_neg_integer()]
          }

    @type t :: %__MODULE__{
            inductive: atom(),
            major_position: non_neg_integer(),
            constructors: [constructor()]
          }
  end

  defmodule BoolRec do
    @moduledoc "Reduction metadata for the non-dependent Bool recursor."
    defstruct []
    @type t :: %__MODULE__{}
  end

  defmodule BoolInd do
    @moduledoc "Reduction metadata for the dependent Bool induction principle."
    defstruct []
    @type t :: %__MODULE__{}
  end

  defmodule NatRec do
    @moduledoc "Reduction metadata for the non-dependent Nat recursor."
    defstruct []
    @type t :: %__MODULE__{}
  end

  defmodule NatInd do
    @moduledoc "Reduction metadata for the dependent Nat induction principle."
    defstruct []
    @type t :: %__MODULE__{}
  end

  defmodule ListRec do
    @moduledoc "Reduction metadata for the non-dependent List recursor."
    defstruct []
    @type t :: %__MODULE__{}
  end

  defmodule ListInd do
    @moduledoc "Reduction metadata for the dependent List induction principle."
    defstruct []
    @type t :: %__MODULE__{}
  end

  @type t ::
          Recursor.t()
          | BoolRec.t()
          | BoolInd.t()
          | NatRec.t()
          | NatInd.t()
          | ListRec.t()
          | ListInd.t()

  @spec known?(term()) :: boolean()
  def known?(%Recursor{} = recursor), do: valid_recursor?(recursor)
  def known?(%BoolRec{}), do: true
  def known?(%BoolInd{}), do: true
  def known?(%NatRec{}), do: true
  def known?(%NatInd{}), do: true
  def known?(%ListRec{}), do: true
  def known?(%ListInd{}), do: true
  def known?(_reduction), do: false

  defp valid_recursor?(%Recursor{
         inductive: inductive,
         major_position: major,
         constructors: constructors
       }) do
    is_atom(inductive) and is_integer(major) and major >= 0 and is_list(constructors) and
      Enum.all?(constructors, &valid_constructor?/1)
  end

  defp valid_constructor?(%{name: name, branch_position: branch_position} = constructor) do
    is_atom(name) and non_neg_integer?(branch_position) and
      positions?(Map.get(constructor, :argument_positions, [])) and
      positions?(Map.get(constructor, :recursive_positions, []))
  end

  defp valid_constructor?(_constructor), do: false

  defp positions?(positions), do: is_list(positions) and Enum.all?(positions, &non_neg_integer?/1)
  defp non_neg_integer?(value), do: is_integer(value) and value >= 0
end
