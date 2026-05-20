defmodule Theoria.Spec.EffectTest do
  use ExUnit.Case, async: true

  alias Theoria.Spec.Effect

  test "compares effect strength" do
    assert Effect.effects() == [:pure, :read, :write, :io, :send, :exception, :unknown]
    assert Effect.leq?(:pure, :read)
    assert Effect.leq?(:read, :write)
    refute Effect.leq?(:write, :read)
    assert Effect.join([:pure, :read, :write]) == :write
  end

  test "detects no-new-effects claims" do
    assert Effect.no_new_effects?([:read, :write], [:pure, :read])
    refute Effect.no_new_effects?([:pure], [:write])

    [delta] = Effect.deltas([:pure], [:write])
    refute Effect.Delta.allowed?(delta)
    assert delta.before == :pure
    assert delta.after == :write
    assert Jason.encode!(delta) =~ "\"allowed\":false"
  end
end
