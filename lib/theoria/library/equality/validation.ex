defmodule Theoria.Library.Equality.Validation do
  @moduledoc "Validation metadata for `Theoria.Library.Equality`."

  alias Theoria.Library.Equality
  alias Theoria.Validation.{Library, TheoremModuleCheck}

  @doc "Returns validation checks owned by the equality library."
  def checks do
    Library.new(TheoremModuleCheck.new(:equality, Equality.Theorems))
  end
end
