defmodule Theoria.Inductive.IndexTest do
  use ExUnit.Case, async: true

  alias Theoria.Env
  alias Theoria.Inductive
  alias Theoria.Inductive.Generate
  alias Theoria.Inductive.{Index, Spec}
  alias Theoria.Library.Nat
  alias Theoria.Normalize
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

  test "generates indexed induction type without iota rules" do
    spec = vec_spec()
    assert {:ok, type} = Generate.indexed_induction_type(spec)
    assert Term.well_scoped?(type)
    assert inspect(type) =~ "motive"
    assert inspect(type) =~ "vec_cons"
  end

  test "completion generates indexed eliminators" do
    assert {:ok, completed} = Inductive.complete(vec_spec())

    assert [
             %Theoria.Inductive.Recursor{
               name: :vec_ind,
               reduction: %Theoria.Env.Reduction.Iota{},
               type: type
             }
           ] = completed.recursors

    assert Term.well_scoped?(type)
  end

  test "installs Vec with generated indexed eliminator" do
    {:ok, spec} = Inductive.complete(vec_spec())
    {:ok, env} = Nat.env()

    assert {:ok, env} = Theoria.Kernel.add_inductive(env, spec)
    assert {:ok, constant} = Env.fetch(env, :vec_ind)
    assert constant.kind == :recursor
    assert constant.reduction == %Theoria.Env.Reduction.Iota{}

    assert %Theoria.Env.Recursor{
             name: :vec_ind,
             inductives: [:Vec],
             num_params: 1,
             num_indices: 1,
             num_motives: 1,
             num_minors: 2,
             rules: [nil_rule, cons_rule]
           } = constant.metadata

    assert %{constructor: :vec_nil, field_count: 0, index_patterns: [zero]} = nil_rule
    assert zero == term(do: zero) |> elab!()
    assert %{constructor: :vec_cons, field_count: 3, index_patterns: [succ_n]} = cons_rule
    assert inspect(succ_n) == "#Theoria<succ #1>"

    metadata = constant.metadata
    assert {:ok, %Theoria.Term.Sort{}} = Theoria.Kernel.infer(env, constant.type)
    assert {:ok, ^metadata} = Env.fetch_recursor(env, :vec_ind)
  end

  test "indexed eliminator reduces Vec nil" do
    {:ok, env} = vec_env()

    term =
      vec_ind_term(
        index: term(do: zero) |> elab!(),
        major: term(do: app(const(:vec_nil, [1]), nat())) |> elab!()
      )

    assert Normalize.defeq?(env, term, term(do: zero) |> elab!())
  end

  test "indexed eliminator reduces Vec cons" do
    {:ok, env} = vec_env()

    tail = term(do: app(const(:vec_nil, [1]), nat())) |> elab!()

    major =
      app_all(Term.const(:vec_cons, [1]), [
        Term.const(:Nat),
        Term.const(:zero),
        Term.const(:zero),
        tail
      ])

    term =
      vec_ind_term(
        index: term(do: app(succ, zero)) |> elab!(),
        major: major
      )

    assert Normalize.defeq?(env, term, term(do: app(succ, zero)) |> elab!())
  end

  test "indexed eliminator does not reduce when explicit index mismatches constructor index pattern" do
    {:ok, env} = vec_env()

    tail = term(do: app(const(:vec_nil, [1]), nat())) |> elab!()

    major =
      app_all(Term.const(:vec_cons, [1]), [
        Term.const(:Nat),
        Term.const(:zero),
        Term.const(:zero),
        tail
      ])

    term =
      vec_ind_term(
        index: term(do: zero) |> elab!(),
        major: major
      )

    assert Normalize.normalize(env, term) == {:ok, term}
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

  defp vec_env do
    with {:ok, spec} <- Inductive.complete(vec_spec()),
         {:ok, env} <- Nat.env() do
      Theoria.Kernel.add_inductive(env, spec)
    end
  end

  defp vec_ind_term(opts) do
    index = Keyword.fetch!(opts, :index)
    major = Keyword.fetch!(opts, :major)
    motive = vec_nat_motive() |> elab!()
    cons_case = vec_nat_cons_case() |> elab!()

    [Term.const(:Nat), motive, Term.const(:zero), cons_case, index, major]
    |> Enum.reduce(Term.const(:vec_ind, [1]), &Term.app(&2, &1))
  end

  defp app_all(fun, args), do: Enum.reduce(args, fun, &Term.app(&2, &1))

  defp vec_nat_motive do
    term do
      lam :n, nat() do
        lam :xs, app(app(const(:Vec, [1]), nat()), n) do
          nat()
        end
      end
    end
  end

  defp vec_nat_cons_case do
    term do
      lam :head, nat() do
        lam :n, nat() do
          lam :tail, app(app(const(:Vec, [1]), nat()), n) do
            lam :ih, nat() do
              app(succ, ih)
            end
          end
        end
      end
    end
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
