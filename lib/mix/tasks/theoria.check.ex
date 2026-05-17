defmodule Mix.Tasks.Theoria.Check do
  @moduledoc """
  Checks Theoria's native validation corpus.

  This task is an alias for `mix theoria.validate`.
  """

  use Mix.Task

  alias Mix.Tasks.Theoria.Validate

  @shortdoc "Checks Theoria's native validation corpus"

  @impl true
  def run(args) do
    Validate.run(args)
  end
end
