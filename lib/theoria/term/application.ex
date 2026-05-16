defmodule Theoria.Term.Application do
  @moduledoc "Helpers for application terms."

  alias Theoria.Term

  @spec collect(Term.t()) :: {Term.t(), [Term.t()]}
  def collect(term), do: collect(term, [])

  defp collect(%Term.App{fun: fun, arg: arg}, args), do: collect(fun, [arg | args])
  defp collect(fun, args), do: {fun, args}
end
