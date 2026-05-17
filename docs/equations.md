# Equation metadata and generated lemmas

Theoria's equation compiler is still internal groundwork, but compiled library definitions already carry auditable equation metadata.

Current flow:

```text
Signature + CaseTemplate + Clause/Pattern
  → Theoria.Equation.SchemaBuilder
  → Theoria.Equation.Compiler
  → Theoria.Equation.Compiled
  → Theoria.Equation.DefinitionSpec package
  → Theoria.Equation.MatcherDescriptor package
  → Theoria.Equation.MatcherType package
  → Theoria.Equation.MatcherSpec package
  → Theoria.Equation.Info metadata in the environment
  → generated Theoria.Equation.Lemma metadata
  → generated Theoria.Equation.MatcherEquation metadata
  → Theoria.Env.Matcher declarations
  → Theoria.Equation.Extension registry helpers
  → Theoria.Equation.Eqns / MatcherEqns lookup
  → optional/lazy theorem realization
  → optional opaque theorem declarations
  → rewrite rules/databases
```

The metadata is Theoria-owned data. It is checked by native validation and can be translated to Lean by the contributor-only oracle, but Lean is not part of the runtime trusted path.

## Stored equation metadata

Compiled definitions such as `bool_not`, `nat_add`, `list_length`, and `list_append` store `Theoria.Equation.Info` in their environment declaration metadata. Use:

```elixir
Theoria.Equation.Info.fetch(env, :nat_add)
Theoria.Equation.Info.all(env)
Theoria.Equation.Info.equation?(env, :nat_add)
```

`Theoria.Equation.Signature` summarizes the function telescope, recursive argument, result type, and fixed parameters. Fixed parameters are derived from the signature's parameter telescope by default, with explicit overrides still available for future edge cases. `Theoria.Equation.CaseTemplate` describes schematic constructor equations without tying schema generation to concrete library definition names. `Theoria.Equation.SchemaBuilder` turns those inputs into validated schemas and matcher metadata, including discriminant names/positions/types and simple overlap records. The compiler returns `Theoria.Equation.Compiled`, which contains the recursor body plus generated clause/schema/matcher metadata. `Theoria.Equation.DefinitionSpec` wraps that compiler result with the final checked definition type/value before installation. `Theoria.Equation.MatcherDescriptor` turns schema/matcher metadata into a structural matcher description with discriminants, alternatives, result, and recursor. `Theoria.Equation.MatcherType` consumes descriptors to generate checked matcher type/body packages. `Theoria.Equation.MatcherSpec` installs those packages as `Theoria.Env.Matcher` metadata. Stored metadata records the definition name, checked type/value, recursive argument position, fixed parameters, level parameters, original clause metadata, Lean-shaped matcher alternatives, matcher discriminants, matcher declaration names, matcher mode, and a validated schema that drives schematic theorem generation.

## Generated equation lemmas

For the currently supported library definitions, Theoria can generate schematic equation-lemma metadata from compiler-owned `Equation.Schema` entries:

```elixir
{:ok, info} = Theoria.Equation.Info.fetch(env, :nat_add)
Theoria.Equation.Lemma.generated_for(info)
#=> [nat_add.eq_zero, nat_add.eq_succ]
```

Supported definitions today:

- `bool_not`
- `bool_and`
- `bool_or`
- `nat_add`
- `list_length`
- `list_append`

These generated lemmas are metadata until explicitly checked or installed. Schematic lemmas carry binders and an equality type, so they can be checked as forall-theorems by reflexivity when the two sides are definitionally equal, and optionally installed as opaque theorem declarations:

```elixir
Theoria.Equation.Lemma.add_generated_to_env(env, :nat_add)
```

The prelude does not install generated equation theorems by default yet.

## Equation lookup

`Theoria.Equation.Eqns` is the small Theoria equivalent of Lean's equation-theorem lookup layer:

```elixir
Theoria.Equation.Eqns.get(env, :nat_add)
#=> {:ok, [:"nat_add.eq_zero", :"nat_add.eq_succ"]}

Theoria.Equation.Eqns.generated(env, :nat_add)
Theoria.Equation.Eqns.unfold(env, :nat_add)
Theoria.Equation.Eqns.source(env, :"nat_add.eq_succ")
Theoria.Equation.Eqns.installed?(env, :nat_add)
```

`Theoria.Equation.MatcherEqns` is the matcher-equation side of the same groundwork and reads first-class matcher declarations from the environment:

```elixir
Theoria.Equation.MatcherEqns.get(env, :"nat_add.match_1")
#=> {:ok, [:"nat_add.match_1.eq_zero", :"nat_add.match_1.eq_succ"]}

Theoria.Equation.MatcherEqns.source(env, :"nat_add.match_1.eq_succ")
#=> {:ok, :"nat_add.match_1"}
```

Generated theorem metadata can also be realized without installing declarations:

```elixir
Theoria.Equation.Eqns.realize(env, :nat_add)
Theoria.Equation.Eqns.realize(env, :"nat_add.eq_succ")
Theoria.Equation.Eqns.realize(env, :"nat_add.eq_def")
Theoria.Equation.MatcherEqns.realize(env, :"nat_add.match_1.eq_succ")
```

`Theoria.Equation.Extension` provides typed registry helpers for source lookup, matcher lookup, unfold names, generated theorem-name enumeration, and an in-memory `Extension.Registry` snapshot. It is currently rebuilt from environment metadata rather than stored as a persistent disk-backed extension.

## Matcher maturity

Matcher declarations have explicit modes:

- `:source_aligned` — the declaration is kernel checked, but its type/value mirror the source definition while the matcher metadata is developed.
- `:matcher` — the declaration has a generated matcher type and body.

Current status:

- unary Bool definitions such as `bool_not` use `:matcher` mode with type `∀ motive, ∀ b, motive → motive → motive` and a Bool recursor body;
- Nat definitions such as `nat_add` use `:matcher` mode with type `∀ motive, ∀ n, motive → (Nat → motive → motive) → motive` and a Nat recursor body;
- List definitions such as `list_length` and `list_append` use `:matcher` mode with a List recursor body;
- binary Bool definitions such as `bool_and` and `bool_or` use `:matcher` mode with two discriminants and four alternatives.

Future stages will add true matcher arity for more families, independently compiled matcher bodies, and persistent matcher equation extensions.

## Rewrite databases

Generated equation lemmas can feed the provisional rewrite database:

```elixir
database = Theoria.Rewrite.Database.from_env_equations(env)
Theoria.Rewrite.Database.once(database, term)
```

The rewrite layer is intentionally untrusted and first-order for now. It can match schematic equation-rule binders, but it does not produce proofs and does not replace kernel checking.

## Simp groundwork

`Theoria.Simp` is a tiny consumer of generated equation databases:

```elixir
Theoria.Simp.once(env, term)
Theoria.Simp.normalize(env, term, max_steps: 100)
```

It repeatedly applies priority-sorted generated equation rewrite rules and returns the final term plus rich `%Theoria.Simp.Step{}` trace entries. It is not a trusted simplifier yet.

A small smoke-test task runs built-in examples:

```bash
mix theoria.simp --examples
```

## Mix tooling

List equation metadata, generated lemma names, matcher metadata, discriminants, alternatives, unfold metadata, and matcher equations:

```bash
mix theoria.equations
mix theoria.equations nat_add
```

Opt-in install generated equation theorems during the task run:

```bash
mix theoria.equations --install nat_add
```

Native validation kernel-checks generated equation theorems, matcher declarations, registry coherence, and lazy realization APIs, then reports them explicitly:

```text
✓ matcher declarations: 6 checked matcher(s)
✓ generated equations: 16 theorem(s)
✓ matcher equations: 16 theorem(s)
```

It can also show equation metadata:

```bash
mix theoria.validate --equations
mix theoria.validate --equations --verbose
```

The verbose form prints generated lemma names under each stored equation definition.

## Limitations

The current generator is deliberately small. It emits schematic equation lemmas from schemas for the built-in Bool/Nat/List definitions, derives fixed parameters from signatures, and stores basic matcher/discriminant/overlap metadata in checked matcher declarations. It is not yet Lean's full equation theorem machinery: there is no public equation syntax, no mutual-recursive fixed-parameter permutation analysis, no discriminant dependency analysis, descriptors are still limited to simple nondependent matchers, no recursor-info extraction from `Env.Recursor`, no dependent/indexed matcher descriptors, registry snapshots are rebuilt in memory and not persisted to disk, no general structural recursion checker, no `brecOn`/below dictionaries, no attribute/prioritized simp database, no full lazy theorem declaration registry, and no proof-producing rewrite tactic.
