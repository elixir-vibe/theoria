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
mix theoria.kernel.check --assurance-summary
mix theoria.kernel.check --assurance-summary --coverage --json
mix theoria.kernel.check --generated-size 4 --generated-max-terms 256
mix theoria.kernel.check --environment-depth 8
```

The report compares production kernel behavior with the independent reference checker/normalizer, checks deterministic generated typed terms with stable family counts, timing, diagnostics, and configurable bounds, summarizes generated artifact proof strategies, replays the Prelude environment, replays theorem-module-installed environments, replays generated/indexed artifact environments, checks generated environment corpora, checks invalid environment rejection cases, and verifies metadata/reduction preservation across replay sources.

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

`Theoria.Simp.Result.proof_strategy/1` reports how the final checked artifact was produced: reflexivity, single step, transitive chain, or definitional-equality fallback. `Theoria.Simp.Result.proof_status_counts/1` summarizes checked/missing/unsupported step proofs in a trace.

## JSON output

JSON output is produced through Jason encoders for report structs and proof diagnostics. Mix tasks should pass structs/maps to `Jason.encode!/1`; do not hand-roll JSON strings.

Capability output has this shape. Nested structural lifts may include `inner` to describe the supported proof method used below the outer constructor path:

```json
{
  "proof_capabilities": [
    {
      "path": ["arg"],
      "capability": {
        "supported": true,
        "reason": "application_congruence",
        "description": "application congruence",
        "inner": null
      }
    }
  ]
}
```

Kernel JSON reports include `timings`, `total_checks`, `total_replay_checks`, `environment_report`, `invalid_environment_checks`, `metadata_replay`, `metadata_replay_checks`, and optional structured `explanation` entries when `--explain` is passed with coverage JSON.

`mix theoria.kernel.check --assurance-summary --coverage --json` returns a smaller envelope:

```json
{
  "summary": {},
  "coverage": {},
  "explanation": null
}
```

Use the summary form for user-facing assurance dashboards and the full report form for diagnostics.
