# Code Context

## Files Retrieved
1. `lib/theoria/rewrite/proof.ex` (lines 1-240, 220-339) - proof attachment, path lifting, app/equality congruence, defeq fallback.
2. `lib/theoria/rewrite/proof/capabilities.ex` (lines 1-57) - advertised proof-lifting capability matrix.
3. `lib/theoria/rewrite/proof/eq_rec.ex` (lines 1-16) - current EqRec boundary helper, only diagnostic delegation.
4. `lib/theoria/rewrite.ex` (lines 1-186) - structural rewrite traversal and path production for EqRec/base/proof/binders.
5. `lib/theoria/kernel.ex` (lines 35-124, 90-169) - kernel inference for lambdas, foralls, equality, refl, and EqRec.
6. `lib/theoria/term.ex` (lines 80-160, 370-489) - EqRec term shape/builders and de Bruijn shift/subst traversal.
7. `lib/theoria/rewrite/proof/result.ex` (lines 1-50) - proof status/result API.
8. `lib/theoria/rewrite/proof/capability.ex` (lines 1-15) - capability descriptor.
9. `lib/theoria/equality.ex` (lines 1-72) - existing EqRec-based equality helper constructors.
10. `lib/theoria/rewrite/step.ex` (lines 1-21) - rewrite step metadata shape.
11. `lib/theoria/rewrite/rule.ex` (lines 1-130) - rewrite rule proof/binder storage and instantiation source.
12. `test/theoria/rewrite_test.exs` (lines 1-170) - current rewrite proof tests, including EqRec boundary and binder rejection cases.

## Key Code

Current proof attachment trusts only terms that the kernel checks against the exact equality for the whole rewrite step:

```elixir
# lib/theoria/rewrite/proof.ex:43-52
defp proof_result(%Env{} = env, %Step{} = step) do
  with {:ok, type} <- Kernel.infer(env, step.before),
       {:ok, proof} <- local_or_defeq_proof(env, type, step),
       :ok <- Kernel.check(env, proof, Term.eq(type, step.before, step.after)) do
    {:ok, proof}
  else
    {:error, %Theoria.Error{}} -> {:error, :kernel_rejected}
    {:error, status} when is_atom(status) -> {:error, status}
  end
end
```

Currently supported non-top-level lifting is app fun/arg and equality left/right only:

```elixir
# lib/theoria/rewrite/proof.ex:96-108
defp lift_path(env, type, proof, %Step{path: [:arg]} = step),
  do: lift_app_arg(env, type, proof, step)

defp lift_path(env, type, proof, %Step{path: [:fun]} = step),
  do: lift_app_fun(env, type, proof, step)

defp lift_path(env, type, proof, %Step{path: [:left]} = step),
  do: lift_eq_left(env, type, proof, step)

defp lift_path(env, type, proof, %Step{path: [:right]} = step),
  do: lift_eq_right(env, type, proof, step)
```

`EqRec` paths are traversed by rewriting, but are deliberately marked as boundaries in capabilities:

```elixir
# lib/theoria/rewrite.ex:109-121
defp replace_child_once_with_path(%Term.EqRec{} = term, from, to, binder_count, path),
  do:
    replace_fields_once_with_path(
      term,
      [:type, :motive, :base, :proof],
      from,
      to,
      binder_count,
      path
    )
```

```elixir
# lib/theoria/rewrite/proof/capabilities.ex:21-28
path in [[:domain], [:body]] ->
  unsupported(:binder_boundary, "binder paths remain kernel-checked boundaries")

path in [[:proof], [:base]] ->
  unsupported(:eq_rec_boundary, "EqRec paths remain kernel-checked boundaries")
```

The kernel gives exactly the API needed for sound EqRec argument congruence. It computes the type of an EqRec by checking:
- `proof : Eq type left right`
- `base : motive left`
- result type is `motive right`

```elixir
# lib/theoria/kernel.ex:99-118
def infer(%Env{} = env, %Context{} = context, %EqRec{
      type: type,
      motive: motive,
      base: base,
      proof: proof
    }) do
  with {:ok, %Sort{}} <- infer_sort(env, context, type),
       {:ok, %Eq{type: proof_type, left: left, right: right}} <-
         infer_equality_proof(env, context, proof),
       :ok <- ensure_defeq(env, proof_type, type, :equality_type_mismatch),
       left_target = %App{fun: motive, arg: left},
       right_target = %App{fun: motive, arg: right},
       {:ok, %Sort{}} <- infer_sort(env, context, left_target),
       {:ok, %Sort{}} <- infer_sort(env, context, right_target),
       :ok <- check(env, context, base, left_target) do
    {:ok, right_target}
  end
end
```

Existing equality lifts build a dependent motive and then let `Kernel.check/3` validate the candidate:

```elixir
# lib/theoria/rewrite/proof.ex:150-178
motive =
  Term.lam(
    :z,
    value_type,
    Term.eq(
      Term.shift(proposition_type, 1),
      Term.eq(Term.shift(value_type, 1), Term.shift(left, 1), Term.shift(right, 1)),
      Term.eq(Term.shift(value_type, 1), Term.bvar(0), Term.shift(right, 1))
    )
  )

check_lifted(
  env,
  proposition_type,
  Term.eq_rec(value_type, motive, Term.refl(step.before), proof),
  step
)
```

The term API is plain enough to synthesize the target EqRec under the motive binder:

```elixir
# lib/theoria/term.ex:90-102
defmodule EqRec do
  @moduledoc "Primitive equality recursor."
  @enforce_keys [:type, :motive, :base, :proof]
  defstruct [:type, :motive, :base, :proof]

  @type t :: %__MODULE__{
          type: Theoria.Term.t(),
          motive: Theoria.Term.t(),
          base: Theoria.Term.t(),
          proof: Theoria.Term.t()
        }
end
```

## Architecture

`Rewrite.once_with_step/2` is intentionally untrusted: it finds the first structural occurrence, records `before`, `after`, `path`, `substitution`, and an instantiated rule proof if available. `Rewrite.Proof.attach/2` is the trust boundary: it infers the type of the whole `step.before`, builds or lifts a candidate proof, and accepts it only if `Kernel.check/3` verifies `candidate : Eq(type, step.before, step.after)`.

Current automation can prove:
- top-level rewrites by using the instantiated rule proof directly;
- application `[:fun]`, `[:arg]`, and nested app-only paths via equality congruence;
- equality side paths `[:left]`, `[:right]` via EqRec motives;
- defeq-only cases via `refl(before)` fallback.

`EqRec` base/proof paths are already found by traversal, and tests currently show trivial same-to-same rewrites as `:checked` only because the defeq fallback (`refl(before)`) succeeds. Non-definitional rewrites under `EqRec.base` or `EqRec.proof` are still not proof-producing.

## Recommendation: add exact EqRec `[:base]` and `[:proof]` lifting first

Smallest sound 0.6 improvement: implement EqRec argument congruence for exact paths `[:base]` and `[:proof]` in `Theoria.Rewrite.Proof`. This is smaller and less risky than binder-domain lifting because it uses the same EqRec motive pattern already used by equality-side lifting, and the existing kernel API can reject every malformed candidate.

### Proposed code shape

Add two clauses near the other exact `lift_path/4` clauses:

```elixir
defp lift_path(env, type, proof, %Step{path: [:base]} = step),
  do: lift_eq_rec_base(env, type, proof, step)

defp lift_path(env, type, proof, %Step{path: [:proof]} = step),
  do: lift_eq_rec_proof(env, type, proof, step)
```

Then add helpers following the `lift_eq_left/right` style:

```elixir
defp lift_eq_rec_base(env, result_type, proof, step) do
  case {step.before, step.after} do
    {%Term.EqRec{} = before, %Term.EqRec{} = after_term}
    when before.type == after_term.type and
           before.motive == after_term.motive and
           before.proof == after_term.proof ->
      with {:ok, base_type} <- Kernel.infer(env, before.base) do
        target = %Term.EqRec{
          before
          | type: Term.shift(before.type, 1),
            motive: Term.shift(before.motive, 1),
            base: Term.bvar(0),
            proof: Term.shift(before.proof, 1)
        }

        motive =
          Term.lam(
            :z,
            base_type,
            Term.eq(Term.shift(result_type, 1), Term.shift(step.before, 1), target)
          )

        check_lifted(env, result_type, Term.eq_rec(base_type, motive, Term.refl(step.before), proof), step)
      end

    _ ->
      {:error, :unsupported_path}
  end
end
```

For `[:proof]`, same idea but infer the type of `before.proof`, keep `base` shifted, and put `Term.bvar(0)` in the proof field:

```elixir
defp lift_eq_rec_proof(env, result_type, proof, step) do
  case {step.before, step.after} do
    {%Term.EqRec{} = before, %Term.EqRec{} = after_term}
    when before.type == after_term.type and
           before.motive == after_term.motive and
           before.base == after_term.base ->
      with {:ok, proof_type} <- Kernel.infer(env, before.proof) do
        target = %Term.EqRec{
          before
          | type: Term.shift(before.type, 1),
            motive: Term.shift(before.motive, 1),
            base: Term.shift(before.base, 1),
            proof: Term.bvar(0)
        }

        motive =
          Term.lam(
            :h,
            proof_type,
            Term.eq(Term.shift(result_type, 1), Term.shift(step.before, 1), target)
          )

        check_lifted(env, result_type, Term.eq_rec(proof_type, motive, Term.refl(step.before), proof), step)
      end

    _ ->
      {:error, :unsupported_path}
  end
end
```

Notes:
- Keep `check_lifted/4` as the final authority; the helper is still untrusted synthesis.
- This does not assume proof irrelevance. `[:proof]` lifting requires an actual rule proof of equality between the old proof term and the new proof term.
- After adding these, update `Capabilities.explain/1` for `[:base]` and `[:proof]` from unsupported `:eq_rec_boundary` to supported reasons such as `:eq_rec_base_congruence` and `:eq_rec_proof_congruence`. Leave deeper paths like `[:base, ...]` unsupported until recursive lifting is deliberately extended.
- `lib/theoria/rewrite/proof/eq_rec.ex` can remain just a diagnostic wrapper, or it can grow these builders later; for the smallest change, keep implementation in `proof.ex` beside the other path lifts.

## Tests to add

Add tests to `test/theoria/rewrite_test.exs` near the existing EqRec boundary tests.

### 1. Non-definitional EqRec base rewrite gets a checked EqRec proof

Use a base rewrite where `refl(before)` cannot be accepted by defeq, so the new lift is required. A good shape is an EqRec whose result type is constant `Nat`:

```elixir
test "EqRec base rewrite steps can carry checked proof" do
  {:ok, env} = Prelude.env()
  nat = Term.const(:Nat)
  zero = Term.const(:zero)
  succ_zero = Term.app(Term.const(:succ), zero)
  motive = Term.lam(:n, nat, Term.shift(nat, 1))
  eq_rec = Term.eq_rec(nat, motive, zero, Term.refl(zero))
  rewritten = Term.eq_rec(nat, motive, succ_zero, Term.refl(zero))

  equality = Term.eq(nat, zero, succ_zero)
  rule = Rule.new(:zero_to_succ_zero, equality, proof: Term.const(:zero_eq_succ_zero))
  {:ok, env} = Theoria.Kernel.add_axiom(env, :zero_eq_succ_zero, equality)

  assert {:ok, step} = Rewrite.once_with_step(eq_rec, rule)
  assert step.path == [:base]
  assert step.after == rewritten
  assert %{proof_result: %{status: :checked, proof: %Term.EqRec{}, capability: %{reason: :eq_rec_base_congruence}}} =
           Proof.attach(env, step)
end
```

The axiom is intentionally local to the test environment; soundness still comes from `Kernel.check/3` validating the generated lift.

### 2. EqRec proof rewrite gets a checked EqRec proof without proof irrelevance

Create two named proofs of the same equality and a third proof equating those proof terms:

```elixir
test "EqRec proof rewrite steps can carry checked proof" do
  {:ok, env} = Prelude.env()
  nat = Term.const(:Nat)
  zero = Term.const(:zero)
  motive = Term.lam(:n, nat, Term.shift(nat, 1))
  equality = Term.eq(nat, zero, zero)
  h1 = Term.const(:h1)
  h2 = Term.const(:h2)
  proof_equality = Term.eq(equality, h1, h2)

  {:ok, env} = Theoria.Kernel.add_axiom(env, :h1, equality)
  {:ok, env} = Theoria.Kernel.add_axiom(env, :h2, equality)
  {:ok, env} = Theoria.Kernel.add_axiom(env, :h1_eq_h2, proof_equality)

  eq_rec = Term.eq_rec(nat, motive, zero, h1)
  rewritten = Term.eq_rec(nat, motive, zero, h2)
  rule = Rule.new(:h1_to_h2, proof_equality, proof: Term.const(:h1_eq_h2))

  assert {:ok, step} = Rewrite.once_with_step(eq_rec, rule)
  assert step.path == [:proof]
  assert step.after == rewritten
  assert %{proof_result: %{status: :checked, proof: %Term.EqRec{}, capability: %{reason: :eq_rec_proof_congruence}}} =
           Proof.attach(env, step)
end
```

This demonstrates the important soundness property: the automation only lifts an explicit equality proof between proofs; it does not assume all equality proofs are equal.

### 3. Capability matrix reflects the new exact support

Either extend the above assertions or add a direct capability test:

```elixir
assert %{supported?: true, reason: :eq_rec_base_congruence} = Proof.Capabilities.explain([:base])
assert %{supported?: true, reason: :eq_rec_proof_congruence} = Proof.Capabilities.explain([:proof])
```

### 4. Keep binder-domain out of scope for this increment

Leave the existing binder test in place. Binder-domain lifting is trickier because changing a lambda domain changes the inferred function type, and dependent bodies may only typecheck under one domain unless transported with more context-sensitive machinery. EqRec base/proof congruence gives useful new proof-producing automation with a much smaller trusted surface.

## Start Here

Start in `lib/theoria/rewrite/proof.ex`. Add exact `[:base]`/`[:proof]` path clauses and helper functions modeled on `lift_eq_left/4`, then update `lib/theoria/rewrite/proof/capabilities.ex` and add the two non-definitional tests in `test/theoria/rewrite_test.exs`.
