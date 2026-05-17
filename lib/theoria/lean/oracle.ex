defmodule Theoria.Lean.Oracle do
  @moduledoc "Runs generated Lean oracle files for contributor validation."

  @default_output Path.join(["_build", "theoria_lean", "oracle.lean"])

  @doc "Writes `source` and checks it with Lean."
  @spec run(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(source, opts \\ []) when is_binary(source) and is_list(opts) do
    path = Keyword.get(opts, :path, @default_output)

    with {:ok, lean} <- lean_executable(opts),
         :ok <- write_source(path, source),
         {output, 0} <- System.cmd(lean, [path], stderr_to_stdout: true) do
      {:ok, %{path: path, output: output}}
    else
      {:error, reason} -> {:error, reason}
      {output, status} -> {:error, {:lean_failed, status, path, output}}
    end
  end

  @doc "Returns the Lean executable path, if available."
  @spec lean_executable(keyword()) :: {:ok, String.t()} | {:error, :lean_not_found}
  def lean_executable(opts \\ []) do
    executable = Keyword.get(opts, :lean, System.get_env("THEORIA_LEAN") || "lean")

    case System.find_executable(executable) do
      nil -> {:error, :lean_not_found}
      path -> {:ok, path}
    end
  end

  defp write_source(path, source) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(path, source)
  end
end
