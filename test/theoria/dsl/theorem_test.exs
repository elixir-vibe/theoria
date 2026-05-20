defmodule Theoria.DSL.TheoremTest do
  use ExUnit.Case, async: true

  defmodule BasicProofs do
    use Theoria.DSL

    theorem :poly_identity, universes: [:u] do
      type do
        term do
          forall :a, sort(u) do
            a ~> a
          end
        end
      end

      proof do
        term do
          lam :a, sort(u) do
            lam :x, a do
              x
            end
          end
        end
      end
    end

    theorem :identity do
      type do
        forall :a, type(0) do
          forall :x, var(:a) do
            var(:a)
          end
        end
      end

      proof do
        lam :a, type(0) do
          lam :x, var(:a) do
            var(:x)
          end
        end
      end
    end

    theorem :bad_identity do
      type do
        forall :a, type(0) do
          forall :x, var(:a) do
            var(:a)
          end
        end
      end

      proof do
        lam :a, type(0) do
          lam :x, var(:a) do
            var(:a)
          end
        end
      end
    end
  end

  test "generates theorem registry" do
    assert BasicProofs.__theoria_theorems__() == [:poly_identity, :identity, :bad_identity]
  end

  test "generates type and proof syntax functions" do
    assert %Theoria.Syntax.Forall{} = BasicProofs.identity_type()
    assert %Theoria.Syntax.Lam{} = BasicProofs.identity_proof()
  end

  test "checks valid theorem" do
    assert {:ok, theorem} = BasicProofs.identity_theorem()
    assert theorem.name == :identity
    assert %Theoria.Term.Forall{} = theorem.type
    assert %Theoria.Term.Lam{} = theorem.proof
  end

  test "checks universe-polymorphic theorem" do
    assert {:ok, theorem} = BasicProofs.poly_identity_theorem()
    assert theorem.name == :poly_identity
    assert theorem.universe_params == [:u]
    assert inspect(theorem) =~ "theorem poly_identity.{u}"
  end

  test "returns kernel error for invalid theorem" do
    assert {:error, error} = BasicProofs.bad_identity_theorem()
    assert error.reason == :type_mismatch
  end

  test "raises clear error for missing theorem type block" do
    assert_compile_error(~r/theorem is missing a type block/, """
    defmodule MissingTypeProof do
      use Theoria.DSL

      theorem :missing_type do
        proof do
          const(:true_intro)
        end
      end
    end
    """)
  end

  test "raises clear error for missing theorem proof block" do
    assert_compile_error(~r/theorem is missing a proof block/, """
    defmodule MissingProofProof do
      use Theoria.DSL

      theorem :missing_proof do
        type do
          const(:True)
        end
      end
    end
    """)
  end

  test "raises clear error for duplicate theorem blocks" do
    assert_compile_error(~r/theorem has duplicate type block/, """
    defmodule DuplicateTypeProof do
      use Theoria.DSL

      theorem :duplicate_type do
        type do
          const(:True)
        end

        type do
          const(:True)
        end

        proof do
          const(:true_intro)
        end
      end
    end
    """)
  end

  test "raises clear error for invalid theorem name" do
    assert_compile_error(~r/theorem name must be an atom/, """
    defmodule InvalidTheoremNameProof do
      use Theoria.DSL

      theorem "truth" do
        type do
          const(:True)
        end

        proof do
          const(:true_intro)
        end
      end
    end
    """)
  end

  defp assert_compile_error(pattern, source) do
    assert_raise ArgumentError, pattern, fn -> Code.compile_string(source) end
  end
end
