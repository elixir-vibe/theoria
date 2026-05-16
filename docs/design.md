# Theoria Design

Theoria is an Elixir-native proof/spec engine inspired by Lean's trusted-kernel architecture. It is not a Lean-compatible implementation and does not call Lean as a backend.

## Goals

- Provide a small trusted kernel for checking proof terms.
- Keep Elixir DSLs, tactics, and automation untrusted: they may generate proofs, but the kernel must check them.
- Support practical specifications for Elixir tools, static analysis, graph algorithms, compiler passes, and data transformations.
- Fit naturally into Elixir projects and CI pipelines.
- Keep data structures friendly to Elixir's gradual set-theoretic type direction by using precise structs and explicit result tuples.

## Non-goals

- Lean syntax compatibility.
- Lean `.olean` compatibility.
- A tactic language in the initial kernel.
- Native code generation.
- A full standard library before the kernel is hardened.

## Trusted boundary

Only `Theoria.Kernel` should decide whether a proof is accepted. Higher-level APIs may be convenient but must remain untrusted.

The intended flow is:

```text
Elixir DSL / tactic / domain-specific prover
  -> named Theoria.Syntax terms
  -> Theoria.Elaborator
  -> core Theoria.Term terms
  -> Theoria.Kernel.check/4
  -> checked theorem or error
```

A bug in a DSL should at worst generate a rejected proof. It must not be able to admit a theorem directly.

## Core terms

The initial core calculus contains:

- universes, represented as `Sort u` over `Theoria.Level` terms;
- de Bruijn bound variables;
- constants with optional universe arguments;
- application;
- lambda abstraction;
- dependent function types (`forall`);
- local definitions (`let`);
- propositional equality;
- reflexivity proofs.

Names stored on core binders are diagnostic metadata. Binding correctness is determined by de Bruijn indices.

## Named syntax

`Theoria.Syntax` provides named surface terms and `Theoria.Elaborator` converts them to de Bruijn-indexed core terms. This layer is untrusted and exists to make library definitions auditable without hand-maintaining indices.

`Theoria.DSL` adds Elixir-friendly `do` block constructors on top of named syntax. It also remains untrusted: it only builds syntax terms or generates functions that elaborate syntax and call the kernel. Inside quoted `term do ... end` blocks, object-language function types can be written with the Elixir operator `~>`:

```elixir
term do
  forall :p, prop() do
    p ~> p
  end
end
```

The `theorem` macro creates a small function trio: `<name>_type/0`, `<name>_proof/0`, and `<name>_theorem/1`. The final function returns a `Theoria.Theorem` only after kernel checking succeeds. Universe-polymorphic theorem declarations can be written with explicit universe parameters:

```elixir
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
```

## Environments

`Theoria.Env` stores checked constants, axioms, definitions, and theorem declarations while preserving declaration insertion order. Constants have no value and represent primitive uninterpreted declarations. Axioms have no value and represent trusted assumptions. Definitions are reducible and unfold during normalization. Theorems store checked proofs but are opaque by default, so normalization does not unfold them. Declarations may carry explicit universe parameters, and constant references provide matching universe arguments. Constants may also carry primitive reduction metadata such as `Theoria.Env.Reduction.NatInd`; the normalizer dispatches through this metadata rather than by hardcoded recursor names. Inductive families are described by `Theoria.Inductive.Spec`, `Theoria.Inductive.Constructor`, and `Theoria.Inductive.Recursor` structs. `Theoria.Inductive.declarations/1` turns a validated spec into a declaration plan (`Theoria.Inductive.Declaration` values), `Theoria.Inductive.check_declarations/2` checks that plan against the kernel without mutating the caller's environment, `Theoria.Inductive.verify_env/2` checks that an environment's declarations match a spec, and `Theoria.Inductive.install/2` installs a spec through existing kernel constant admission. `Theoria.Kernel.add_inductive/2` is the canonical bootstrap admission API and currently delegates through these checks. Bool, Nat, and List install their primitive declarations from these specs, then add ordinary checked definitions such as `nat_add` and `list_length`; Bool/Nat/List eliminators are generated from recognized constructor shapes. `Theoria.Inductive.shape/1` classifies the currently supported shapes (`:bool_like`, `:nat_like`, `:list_like`), and `Theoria.Inductive.complete/1` fills missing eliminators for known shapes. Spec validation includes a first strict-positivity pass that rejects recursive occurrences in negative constructor positions, such as `(Bad → Nat) → Bad`. This is currently a conservative bootstrap path, not yet full arbitrary inductive support. A declaration enters the environment safely through kernel functions that verify its type and, for definitions/theorems, its value. Raw environment constructors remain available for tests and tooling, but malformed environments can be rechecked with `Theoria.Kernel.validate_env/1`. Declaration dependencies can be inspected with `Theoria.Kernel.dependencies/2`, which collects constants referenced by a declaration's type and value. Use `Theoria.Kernel.transitive_dependencies/2` to walk those dependencies recursively, `Theoria.Kernel.axioms/2` to report trusted axiom assumptions used by a declaration, and `Theoria.Kernel.trust_report/2` for a `Theoria.Kernel.TrustReport` summary.

`Theoria.Prelude.env/0` is the standard environment for users and downstream tooling. It composes the built-in libraries in dependency order: Logic, Bool, Nat, then List.

`mix theoria.check` checks theorem corpora against the prelude and is part of CI. With no arguments it checks built-in theorem modules; with module arguments it checks those user-provided theorem modules.

## Normalization and definitional equality

The initial normalizer supports beta reduction, zeta reduction for local definitions, unfolding checked definitions, and primitive recursor reductions. Definitional equality currently normalizes both sides and compares the resulting terms structurally.

Normalization is bounded by `Theoria.Normalize.Fuel`, a shared fuel budget defaulting to 10,000 steps:

```elixir
Theoria.Normalize.normalize(env, term, max_steps: 10_000)
Theoria.Normalize.whnf(env, term, max_steps: 10_000)
Theoria.Normalize.defeq?(env, left, right, max_steps: 10_000)
```

This keeps malformed or adversarial environments from unfolding forever. Later versions may need memoization and more careful unfolding control.

## Universe model

Universe levels are represented by `Theoria.Level` structs:

```elixir
Level.zero()
Level.succ(level)
Level.max(left, right)
Level.param(:u)
```

Closed numeric levels are still accepted by public constructors, so `sort(0)` remains the proposition universe. The kernel rule is now:

```text
Sort u : Sort (succ u)
```

Constants can be universe-polymorphic by declaring parameters and applying constants with matching level arguments:

```elixir
{:ok, env} = Kernel.add_constant(env, :Box, sort(Level.param(:u)), [:u])
Kernel.infer(env, const(:Box, [0]))
#=> {:ok, sort(0)}
```

The DSL distinguishes propositions from computational types:

```text
prop()   = Sort 0
type(0) = Sort 1
type(n) = Sort (n + 1)
```

The kernel follows Lean's Prop-valued dependent-function rule in the small: if a `forall` body is a proposition, the whole `forall` lives in `Prop`; otherwise it lives in the maximum relevant type universe. Equality currently infers `Sort 0` as a proposition-like type. This is intentionally provisional and should be revisited when the logic layer grows.

## Inspect and pretty-printing

Core terms and checked theorems implement Elixir's `Inspect` protocol via `Theoria.Pretty`. This keeps everyday `IO.inspect/1`, `dbg/1`, and assertion failures readable while preserving pure rendering functions for future UI and documentation use.

## Relationship to Elixir set-theoretic types

Elixir's set-theoretic types describe sets of Elixir runtime values. Theoria checks terms in its own object language. These are complementary:

- Elixir types help make Theoria's implementation and API safer.
- Theoria's kernel checks mathematical proof/spec terms that Elixir's type system does not express.

## Logic library

`Theoria.Library.Logic` extends an environment with the first logical declarations. It keeps logic outside the kernel where possible: `not` is a checked definition, while `False`, `True`, `and`, and constructors/eliminators are environment constants for now.

This is a pragmatic bootstrap point. Once the calculus grows inductive families and a clearer `Prop` story, some primitive logical constants can be revisited as library-defined encodings.

## Bool library

`Theoria.Library.Bool` introduces the first computational data declarations: `Bool`, `true`, `false`, `bool_rec.{u}`, `bool_ind.{u}`, `bool_not`, `bool_and`, and `bool_or`. These are distinct from logical `True` and `False` propositions. The recursor is universe-polymorphic in its result type, while `bool_ind` is the dependent induction principle:

```text
bool_ind.{u} :
  ∀ motive : Bool → Sort u,
  motive true →
  motive false →
  ∀ b : Bool, motive b
```

The normalizer has primitive reductions for `bool_rec _ t f true`, `bool_rec _ t f false`, `bool_ind motive t f true`, and `bool_ind motive t f false`, so boolean definitions and dependent case analysis can compute during definitional equality.

## Nat library

`Theoria.Library.Nat` introduces natural numbers with `Nat`, `zero`, `succ`, `nat_rec.{u}`, `nat_ind.{u}`, and `nat_add`. The recursor is universe-polymorphic in its result type, while `nat_ind` is the first dependent induction principle:

```text
nat_ind.{u} :
  ∀ motive : Nat → Sort u,
  motive zero →
  (∀ n : Nat, motive n → motive (succ n)) →
  ∀ n : Nat, motive n
```

The normalizer reduces `nat_rec _ z s zero` to `z`, `nat_rec _ z s (succ n)` to `s n (nat_rec _ z s n)`, `nat_ind motive z s zero` to `z`, and `nat_ind motive z s (succ n)` to `s n (nat_ind motive z s n)`, enabling simple arithmetic and dependent induction examples to check by reflexivity.

## List library

`Theoria.Library.List` introduces universe-polymorphic lists with `List.{u}`, `list_nil.{u}`, `list_cons.{u}`, `list_rec.{u,v}`, `list_ind.{u,v}`, and `list_length.{u}`. `Theoria.Library.List.env/0` composes with `Theoria.Library.Nat.env/0` because length computes into `Nat`. Until Theoria has implicit arguments or level inference, the quoted DSL defaults `list(a)`, `list_nil`, `list_cons`, and `list_length(...)` to universe level `1`, and `list_rec(...)`/`list_ind(...)` to levels `{1, 1}`, matching current Bool/Nat examples. The dependent induction principle is:

```text
list_ind.{u,v} :
  ∀ A : Sort u,
  ∀ motive : List.{u} A → Sort v,
  motive (list_nil.{u} A) →
  (∀ x : A, ∀ xs : List.{u} A,
    motive xs → motive (list_cons.{u} A x xs)) →
  ∀ xs : List.{u} A, motive xs
```

The normalizer reduces `list_rec _ _ n c (list_nil _)` to `n`, `list_rec _ _ n c (list_cons _ x xs)` to `c x xs (list_rec _ _ n c xs)`, and the corresponding `list_ind` nil/cons cases analogously.

## Near-term roadmap

1. Add richer Bool/Nat/List theorem corpora.
2. Add theorem documentation generation.
3. Add finite graph/spec libraries for tools such as Reach.
