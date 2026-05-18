defmodule Theoria.Lean.Oracle do
  @moduledoc "Experimental/internal API for 0.1; subject to change before 0.2. Runs generated Lean oracle files for contributor validation."

  @default_output Path.join(["_build", "theoria_lean", "oracle.lean"])

  @doc "Writes `source` and checks it with Lean."
  @spec run(String.t(), keyword()) :: {:ok, map()} | {:error, term()}
  def run(source, opts \\ []) when is_binary(source) and is_list(opts) do
    path = Keyword.get(opts, :path, @default_output)

    with {:ok, lean} <- lean_executable(opts),
         :ok <- write_source(path, source),
         {output, 0} <- System.cmd(lean, [path], stderr_to_stdout: true) do
      {:ok, %{path: path, output: output, lean: lean, version: lean_version(lean)}}
    else
      {:error, reason} -> {:error, reason}
      {output, status} -> {:error, {:lean_failed, status, path, output}}
    end
  end

  @doc "Returns the Lean executable path, if available."
  @spec lean_executable(keyword()) :: {:ok, String.t()} | {:error, :lean_not_found}
  def lean_executable(opts \\ []) do
    opts
    |> configured_executable()
    |> resolve_executable()
  end

  defp configured_executable(opts) do
    Keyword.get(opts, :lean) || System.get_env("THEORIA_LEAN") || elan_toolchain_lean() || "lean"
  end

  defp elan_toolchain_lean do
    with {:ok, toolchains_dir} <- elan_toolchains_dir(),
         {:ok, toolchain} <- newest_lean4_toolchain(toolchains_dir) do
      Path.join([toolchains_dir, toolchain, "bin", "lean"])
    else
      _other -> nil
    end
  end

  defp elan_toolchains_dir do
    cond do
      elan_home = System.get_env("ELAN_HOME") ->
        {:ok, Path.join(elan_home, "toolchains")}

      home = System.get_env("HOME") ->
        {:ok, Path.join([home, ".elan", "toolchains"])}

      true ->
        :error
    end
  end

  defp newest_lean4_toolchain(toolchains_dir) do
    toolchains_dir
    |> File.ls()
    |> case do
      {:ok, entries} -> select_lean4_toolchain(entries)
      {:error, _reason} -> :error
    end
  end

  defp select_lean4_toolchain(entries) do
    entries
    |> Enum.filter(&lean4_toolchain?/1)
    |> Enum.sort(:desc)
    |> List.first()
    |> case do
      nil -> :error
      toolchain -> {:ok, toolchain}
    end
  end

  defp lean4_toolchain?("leanprover--lean4---" <> suffix) do
    not String.ends_with?(suffix, [".tmp", ".lock"])
  end

  defp lean4_toolchain?(_entry), do: false

  defp resolve_executable(path) do
    cond do
      Path.type(path) == :absolute and File.exists?(path) ->
        {:ok, path}

      executable = System.find_executable(path) ->
        {:ok, executable}

      true ->
        {:error, :lean_not_found}
    end
  end

  defp lean_version(lean) do
    case System.cmd(lean, ["--version"], stderr_to_stdout: true) do
      {version, 0} -> String.trim(version)
      {_output, _status} -> "unknown"
    end
  end

  defp write_source(path, source) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    File.write!(path, source)
  end
end
