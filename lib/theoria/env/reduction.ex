defmodule Theoria.Env.Reduction do
  @moduledoc "Primitive reduction metadata attached to environment declarations."

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

  @type t :: BoolRec.t() | BoolInd.t() | NatRec.t() | NatInd.t() | ListRec.t() | ListInd.t()

  @spec known?(term()) :: boolean()
  def known?(%BoolRec{}), do: true
  def known?(%BoolInd{}), do: true
  def known?(%NatRec{}), do: true
  def known?(%NatInd{}), do: true
  def known?(%ListRec{}), do: true
  def known?(%ListInd{}), do: true
  def known?(_reduction), do: false
end
