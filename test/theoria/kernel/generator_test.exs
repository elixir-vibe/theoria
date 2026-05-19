defmodule Theoria.Kernel.GeneratorTest do
  use ExUnit.Case, async: true
  use ExUnitProperties

  alias Theoria.Kernel
  alias Theoria.Kernel.GeneratedTerm
  alias Theoria.Kernel.Generator
  alias Theoria.Kernel.Reference
  alias Theoria.Kernel.Reference.Normalize, as: ReferenceNormalize
  alias Theoria.Normalize

  property "generated typed terms agree between production and reference" do
    check all(%GeneratedTerm{env: env, term: term, type: type} <- Generator.small_terms(size: 3)) do
      assert Kernel.infer(env, term) == Reference.infer(env, term)
      assert Kernel.check(env, term, type) == Reference.check(env, term, type)
      assert Normalize.normalize(env, term) == ReferenceNormalize.normalize(env, term)
    end
  end
end
