defmodule Theoria do
  @moduledoc """
  An Elixir-native proof/spec kernel inspired by Lean's trusted-kernel design.

  Theoria's public DSL will remain untrusted: macros and tactics may generate
  proof terms, but only `Theoria.Kernel` can admit checked constants and
  definitions into an environment.
  """

  alias Theoria.Env

  @doc "Returns an empty kernel environment."
  def new_env, do: Env.new()

  @doc "Returns the standard prelude environment."
  def prelude_env, do: Theoria.Prelude.env()
end
