# 0.5 development boundary

The 0.5 line focuses on reportable assurance, structured proof diagnostics, and clearer proof-producing simplification boundaries.

## Assurance reports

Kernel differential reports now include reference replay of the Prelude environment, theorem-module-installed environment replay, generated artifact replay, indexed artifact replay, coverage summaries, structured explanations, and timing metadata.

```bash
mix theoria.kernel.check
mix theoria.kernel.check --verbose
mix theoria.kernel.check --coverage
mix theoria.kernel.check --explain
mix theoria.kernel.check --json --coverage --explain
```

Reports use structs and Jason encoders for theorem-module summaries, artifact replay skips, kernel explanations, and timing metadata.

## Proof diagnostics

Rewrite and simp steps carry a structured proof result:

```elixir
step.proof_result.status
step.proof_result.capability
step.proof_result.proof
```

Convenience helpers are available on `Theoria.Rewrite.Proof.Result`, `Theoria.Simp.Step`, and `Theoria.Simp.Result`.

`mix theoria.simp --capabilities` prints the current proof capability matrix. `mix theoria.simp --explain` prints step-level capability and status information while running examples.

## Equality chains

Simp artifacts now expose proof strategy metadata:

- `:refl`
- `:single`
- `:transitive`
- `:fallback_defeq`

The strategy is available directly on `%Theoria.Simp.Result{}` and on the realized artifact.

## Boundaries

Application and selected equality-side paths can produce checked lifted proofs. Binder and EqRec paths remain explicit kernel-checked boundaries: defeq-safe cases may still be checked via final reflexivity, but there is no extra axiom or unsound extensionality shortcut.

## Reference coverage

Reference checks include generated typed dependent fragments and direct EqRec-over-refl normalization tests. Lean remains a contributor-only external oracle, not a trusted runtime dependency.
