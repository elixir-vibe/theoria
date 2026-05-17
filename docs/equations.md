# Equation metadata and generated lemmas

Theoria's equation compiler is still internal groundwork, but compiled library definitions already carry auditable equation metadata.

Current flow:

```text
compiled definition
  → Theoria.Equation.Info metadata in the environment
  → generated Theoria.Equation.Lemma metadata
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

The metadata records the definition name, checked type/value, recursive argument position, fixed parameters, level parameters, and optional matcher metadata.

## Generated equation lemmas

For the currently supported library definitions, Theoria can generate closed equation-lemma metadata:

```elixir
{:ok, info} = Theoria.Equation.Info.fetch(env, :nat_add)
Theoria.Equation.Lemma.generated_for(info)
#=> [nat_add.eq_zero_zero, nat_add.eq_one_zero, nat_add.eq_two_zero]
```

Supported definitions today:

- `bool_not`
- `bool_and`
- `bool_or`
- `nat_add`
- `list_length`
- `list_append`

These generated lemmas are metadata until explicitly checked or installed. They can be converted into native defeq validation checks, checked as reflexivity theorems when the two sides are definitionally equal, and optionally installed as opaque theorem declarations:

```elixir
Theoria.Equation.Lemma.add_generated_to_env(env, :nat_add)
```

The prelude does not install generated equation theorems by default yet.

## Rewrite databases

Generated equation lemmas can feed the provisional rewrite database:

```elixir
database = Theoria.Rewrite.Database.from_env_equations(env)
Theoria.Rewrite.Database.once(database, term)
```

The rewrite layer is intentionally untrusted and structural for now. It does not perform unification, does not produce proofs, and does not replace kernel checking.

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

Native validation can also show equation metadata:

```bash
mix theoria.validate --equations
mix theoria.validate --equations --verbose
```

The verbose form prints generated lemma names under each stored equation definition.

## Limitations

The current generator is deliberately small. It emits closed equation lemmas for the built-in Bool/Nat/List definitions. It is not yet Lean's full equation theorem machinery: there is no public equation syntax, no matcher equation generation, no structural recursion checker, no `brecOn`/below dictionaries, no unification-based simp, and no proof-producing rewrite tactic.
