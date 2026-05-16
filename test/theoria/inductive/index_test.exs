defmodule Theoria.Inductive.IndexTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Inductive
  alias Theoria.Inductive.{Index, Spec}
  alias Theoria.Library.Nat
  alias Theoria.Term

  import Theoria.DSL

  test "builds specs with explicit indices" do
    spec = vec_spec()

    assert [%Index{name: :n, type: type} = index] = spec.indices
    assert type == term(do: nat()) |> elab!()
    assert inspect(index) == "#Theoria<index n : Nat>"
  end

  test "validates and installs indexed specs without generated eliminators" do
    assert :ok = Inductive.validate(vec_spec())
    assert {:ok, declarations} = Inductive.declarations(vec_spec())
    assert Enum.map(declarations, & &1.name) == [:Vec, :vec_nil, :vec_cons]

    {:ok, env} = Nat.env()
    assert {:ok, env} = Theoria.Kernel.add_inductive(env, vec_spec())
    assert Inductive.verify_env(env, vec_spec()) == :ok
  end

  test "rejects indexed constructor results with missing index arguments" do
    spec = replace_first_constructor_type(bad_vec_nil_type())

    assert {:error, error} = Inductive.validate(spec)
    assert error.reason == :invalid_inductive
    assert Keyword.fetch!(error.details, :problem) == :constructor_result_arity_mismatch
    assert Keyword.fetch!(error.details, :constructor) == :vec_nil
  end

  test "rejects out-of-scope result index arguments" do
    spec = replace_first_constructor_type(out_of_scope_index_type())

    assert {:error, error} = Inductive.validate(spec)
    assert error.reason == :invalid_inductive
    assert Keyword.fetch!(error.details, :problem) == :constructor_index_scope_mismatch
    assert Keyword.fetch!(error.details, :constructor) == :vec_nil
  end

  test "rejects out-of-scope constructor argument types" do
    spec = replace_first_constructor_type(out_of_scope_argument_type())

    assert {:error, error} = Inductive.validate(spec)
    assert error.reason == :invalid_inductive
    assert Keyword.fetch!(error.details, :problem) == :constructor_argument_scope_mismatch
    assert Keyword.fetch!(error.details, :constructor) == :vec_nil
  end

  test "environment-backed checks reject missing dependencies" do
    assert Inductive.validate(vec_spec()) == :ok
    assert {:error, error} = Inductive.check_spec(Env.new(), vec_spec())
    assert error.reason == :invalid_inductive
    assert Keyword.fetch!(error.details, :problem) == :invalid_inductive_type
  end

  test "indexed specs install only when dependencies are present" do
    assert {:error, error} = Theoria.Kernel.add_inductive(Env.new(), vec_spec())
    assert error.reason == :invalid_inductive

    {:ok, env} = Nat.env()
    assert {:ok, _env} = Theoria.Kernel.add_inductive(env, vec_spec())
  end

  defp replace_first_constructor_type(type) do
    spec = vec_spec()
    [first | rest] = spec.constructors
    %Spec{spec | constructors: [%{first | type: type} | rest]}
  end

  defp vec_spec do
    u = Theoria.Level.param(:u)

    :Vec
    |> Spec.new(vec_type(u), universe_params: [:u])
    |> Spec.parameter(:a, term(do: sort(^u)) |> elab!())
    |> Spec.index(:n, term(do: nat()) |> elab!())
    |> Spec.constructor(:vec_nil, vec_nil_type(u))
    |> Spec.constructor(:vec_cons, vec_cons_type(u))
  end

  defp vec_type(u) do
    term do
      forall :a, sort(^u) do
        nat() ~> sort(^u)
      end
    end
    |> elab!()
  end

  defp vec_nil_type(u) do
    term do
      forall :a, sort(^u) do
        app(app(const(:Vec, [^u]), a), zero)
      end
    end
    |> elab!()
  end

  defp vec_cons_type(u) do
    term do
      forall :a, sort(^u) do
        a
        ~> forall :n, nat() do
          app(app(const(:Vec, [^u]), a), n)
          ~> app(app(const(:Vec, [^u]), a), app(succ, n))
        end
      end
    end
    |> elab!()
  end

  defp bad_vec_nil_type do
    u = Theoria.Level.param(:u)

    term do
      forall :a, sort(^u) do
        app(const(:Vec, [^u]), a)
      end
    end
    |> elab!()
  end

  defp out_of_scope_index_type do
    u = Theoria.Level.param(:u)

    Term.forall(
      :a,
      Term.sort(u),
      Term.app(Term.app(Term.const(:Vec, [u]), Term.bvar(0)), Term.bvar(99))
    )
  end

  defp out_of_scope_argument_type do
    u = Theoria.Level.param(:u)

    Term.forall(
      :a,
      Term.sort(u),
      Term.forall(
        :bad,
        Term.bvar(99),
        Term.app(Term.app(Term.const(:Vec, [u]), Term.bvar(1)), Term.const(:zero))
      )
    )
  end
end
