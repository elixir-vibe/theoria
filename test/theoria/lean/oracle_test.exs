defmodule Theoria.Lean.OracleTest do
  use ExUnit.Case, async: true

  alias Theoria.Lean.Oracle

  test "explicit lean option wins" do
    assert Oracle.lean_executable(lean: "/definitely/missing/lean") == {:error, :lean_not_found}
  end

  test "finds a local elan lean4 toolchain without hardcoded version" do
    case Oracle.lean_executable([]) do
      {:ok, lean} ->
        assert String.ends_with?(lean, "/bin/lean")
        assert File.exists?(lean)

      {:error, :lean_not_found} ->
        :ok
    end
  end
end
