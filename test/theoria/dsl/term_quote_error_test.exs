defmodule Theoria.DSL.TermQuoteErrorTest do
  use ExUnit.Case, async: true

  test "rejects multi-expression term blocks" do
    assert_raise ArgumentError, ~r/term blocks must contain exactly one expression/, fn ->
      eval_term("""
      p
      q
      """)
    end
  end

  test "rejects Elixir numbers" do
    assert_raise ArgumentError, ~r/term blocks do not support Elixir numbers: 123/, fn ->
      eval_term("123")
    end
  end

  test "rejects Elixir strings" do
    assert_raise ArgumentError, ~r/term blocks do not support Elixir strings: "hello"/, fn ->
      eval_term(~s("hello"))
    end
  end

  test "rejects Elixir lists" do
    assert_raise ArgumentError, ~r/use list_nil\/list_cons constants/, fn ->
      eval_term("[x]")
    end
  end

  test "rejects Elixir tuples" do
    assert_raise ArgumentError, ~r/term blocks do not support Elixir tuples/, fn ->
      eval_term("{x, y}")
    end
  end

  test "guides common uppercase type aliases" do
    assert_raise ArgumentError, ~r/use bool\(\)/, fn ->
      eval_term("Bool")
    end

    assert_raise ArgumentError, ~r/use nat\(\)/, fn ->
      eval_term("Nat")
    end

    assert_raise ArgumentError, ~r/use list\(element_type\)/, fn ->
      eval_term("List")
    end
  end

  test "guides malformed binders" do
    assert_raise ArgumentError, ~r/expected forall binder syntax/, fn ->
      eval_term("forall(:p)")
    end

    assert_raise ArgumentError, ~r/expected lambda binder syntax/, fn ->
      eval_term("lam(:p)")
    end

    assert_raise ArgumentError, ~r/expected let syntax/, fn ->
      eval_term("let(:x)")
    end
  end

  defp eval_term(body) do
    Code.eval_string("""
    import Theoria.DSL

    term do
      #{body}
    end
    """)
  end
end
