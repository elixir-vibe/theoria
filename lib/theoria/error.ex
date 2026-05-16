defmodule Theoria.Error do
  @moduledoc "Kernel error returned when a term cannot be checked."

  defexception [:reason, :details]

  @type t :: %__MODULE__{reason: atom(), details: term()}

  @impl true
  def message(%__MODULE__{reason: reason, details: details}) do
    "#{reason}: #{inspect(details)}"
  end
end
