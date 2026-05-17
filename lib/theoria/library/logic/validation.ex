defmodule Theoria.Library.Logic.Validation do
  @moduledoc "Validation metadata for `Theoria.Library.Logic`."

  alias Theoria.Library.Logic
  alias Theoria.Validation.{Library, TheoremModuleCheck}

  @doc "Returns validation checks owned by the logic library."
  def checks do
    Library.new(TheoremModuleCheck.new(:logic, Logic.Theorems))
  end
end
