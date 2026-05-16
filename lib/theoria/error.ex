defmodule Theoria.Error do
  @moduledoc "Kernel error returned when a term cannot be checked."

  defexception [:reason, :details]

  @type t :: %__MODULE__{reason: atom(), details: term()}

  @impl true
  def message(%__MODULE__{} = error) do
    Theoria.Pretty.error(error)
  end
end
