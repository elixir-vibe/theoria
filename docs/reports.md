# CLI reports

Theoria exposes native reports for validation, assurance, and proof-producing simplification diagnostics.

## Native validation

```bash
mix theoria.validate
```

Runs the Theoria-owned validation corpus: theorem modules, defeq checks, inductive specs, equation metadata, generated artifacts, matcher declarations, and explicit indexed matcher validation.

## Kernel differential assurance

```bash
mix theoria.kernel.check
mix theoria.kernel.check --verbose
mix theoria.kernel.check --coverage
mix theoria.kernel.check --explain
mix theoria.kernel.check --json --coverage --explain
```

The report compares production kernel behavior with the independent reference checker/normalizer, replays the Prelude environment, replays theorem-module-installed environments, and replays generated/indexed artifact environments.

These reports are assurance, not a formal proof of kernel correctness. The trusted boundary remains native kernel checking of declarations and artifacts.

## Simplification proof diagnostics

```bash
mix theoria.simp --capabilities
mix theoria.simp --capabilities --json
mix theoria.simp nat_add_zero --prove --explain
mix theoria.simp nat_add_zero --prove --explain --json
```

Simp steps expose structured proof results:

```elixir
step.proof_result.status
step.proof_result.capability
step.proof_result.proof
```

`Theoria.Simp.Result.proof_strategy/1` reports how the final checked artifact was produced: reflexivity, single step, transitive chain, or definitional-equality fallback.

## JSON output

JSON output is produced through Jason encoders for report structs and proof diagnostics. Mix tasks should pass structs/maps to `Jason.encode!/1`; do not hand-roll JSON strings.
