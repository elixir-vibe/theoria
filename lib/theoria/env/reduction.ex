defmodule Theoria.Env.Reduction do
  @moduledoc "Primitive reduction metadata attached to environment declarations."

  defmodule Iota do
    @moduledoc "Marks a recursor declaration as using constructor iota-reduction rules."
    defstruct []
    @type t :: %__MODULE__{}
  end

  @type t :: Iota.t()

  @spec known?(term()) :: boolean()
  def known?(%Iota{}), do: true
  def known?(_reduction), do: false
end
