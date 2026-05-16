defmodule Theoria.Library.LogicTest do
  use ExUnit.Case, async: true

  alias Theoria.Kernel
  alias Theoria.Library.Logic
  alias Theoria.Normalize

  import Theoria.Term

  test "extends an environment with checked logic declarations" do
    assert {:ok, env} = Logic.env()

    for name <- [
          :False,
          :True,
          :true_intro,
          :false_elim,
          :not,
          :and,
          :and_intro,
          :and_left,
          :and_right
        ] do
      assert {:ok, _type} = Kernel.infer(env, const(name))
    end
  end

  test "not unfolds to implication into False" do
    {:ok, env} = Logic.env()

    term = app(const(:not), const(:True))
    expected = arrow(const(:True), const(:False))

    assert Normalize.defeq?(env, term, expected)
  end

  test "and_intro proves True and True conjunction" do
    {:ok, env} = Logic.env()

    proof =
      const(:and_intro)
      |> app(const(:True))
      |> app(const(:True))
      |> app(const(:true_intro))
      |> app(const(:true_intro))

    expected = const(:and) |> app(const(:True)) |> app(const(:True))

    assert :ok = Kernel.check(env, proof, expected)
  end
end
