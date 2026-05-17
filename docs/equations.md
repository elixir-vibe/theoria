# Equation metadata and generated lemmas

Theoria's equation compiler is still internal groundwork, but compiled library definitions already carry auditable equation metadata.

Current flow:

```text
compiled definition
  → Theoria.Equation.DefinitionSpec package
  → Theoria.Equation.Info metadata in the environment
  → generated Theoria.Equation.Lemma metadata
  → Theoria.Equation.Eqns lookup
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

The metadata records the definition name, checked type/value, recursive argument position, fixed parameters, level parameters, original clause metadata, Lean-shaped matcher alternatives, and a validated schema that drives schematic theorem generation. `Theoria.Equation.DefinitionSpec` is the internal package passed from compiled definitions into the kernel environment.

## Generated equation lemmas

For the currently supported library definitions, Theoria can generate schematic equation-lemma metadata from stored `Equation.Schema` entries:

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
Theoria.Equation.Eqns.installed?(env, :nat_add)
```

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

List equation metadata and generated lemma names:

```bash
mix theoria.equations
mix theoria.equations nat_add
```

Opt-in install generated equation theorems during the task run:

```bash
mix theoria.equations --install nat_add
```

Native validation kernel-checks generated equation theorems and reports them explicitly:

```text
✓ generated equations: 16 theorem(s)
```

It can also show equation metadata:

```bash
mix theoria.validate --equations
mix theoria.validate --equations --verbose
```

The verbose form prints generated lemma names under each stored equation definition.

## Limitations

The current generator is deliberately small. It emits schematic equation lemmas from schemas for the built-in Bool/Nat/List definitions and stores basic matcher metadata. It is not yet Lean's full equation theorem machinery: there is no public equation syntax, no general structural recursion checker, no `brecOn`/below dictionaries, no attribute/prioritized simp database, and no proof-producing rewrite tactic.
