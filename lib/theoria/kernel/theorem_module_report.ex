defmodule Theoria.Kernel.TheoremModuleReport do
  @moduledoc "Assurance summary for one theorem module."

  @enforce_keys [:module, :checks, :replay_checks, :replay_skipped, :failures]
  defstruct [:module, :checks, :replay_checks, :replay_skipped, :failures]

  @type t :: %__MODULE__{
          module: module(),
          checks: non_neg_integer(),
          replay_checks: non_neg_integer(),
          replay_skipped: non_neg_integer(),
          failures: [term()]
        }
end
