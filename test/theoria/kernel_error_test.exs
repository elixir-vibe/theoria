defmodule Theoria.KernelErrorTest do
  use ExUnit.Case, async: true

  alias Theoria.Context
  alias Theoria.Env
  alias Theoria.Kernel

  import Theoria.Term

  test "rejects unbound variables" do
    assert {:error, error} = Kernel.infer(Env.new(), bvar(0))
    assert error.reason == :unbound_variable
  end

  test "rejects unknown constants" do
    assert {:error, error} = Kernel.infer(Env.new(), const(:missing))
    assert error.reason == :unknown_constant
  end

  test "rejects applying non-functions" do
    context = Context.new() |> Context.push(:x, sort(0))

    assert {:error, error} = Kernel.infer(Env.new(), context, app(bvar(0), bvar(0)))
    assert error.reason == :not_a_function
  end

  test "rejects constants whose declared type is not a type" do
    assert {:error, error} = Kernel.add_constant(Env.new(), :bad, bvar(0))
    assert error.reason == :unbound_variable
  end
end
