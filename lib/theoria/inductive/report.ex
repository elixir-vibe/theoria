defmodule Theoria.Inductive.Report do
  @moduledoc "Summary of an inductive declaration plan."

  @enforce_keys [:name, :shape, :universe_params, :declarations]
  defstruct [:name, :shape, :universe_params, declarations: []]

  @type t :: %__MODULE__{
          name: atom(),
          shape: :bool_like | :nat_like | :list_like | :unknown,
          universe_params: [atom()],
          declarations: [atom()]
        }
end
