defprotocol Theoria.Validation.Checkable do
  @moduledoc "Protocol for running Theoria validation checks."

  @doc "Runs a validation check against the standard prelude environment."
  @spec check(t(), Theoria.Env.t()) :: :ok | {:error, term()}
  def check(check, env)
end
