# 0.6 release checklist

The 0.6 line is release-ready when the proof-producing automation and generated assurance surfaces are validated and documented.

## Acceptance criteria

- Kernel differential reports include structured generated-term reports and proof-strategy reports.
- Generated-term defaults are documented and configurable with `--generated-size` and `--generated-max-terms`.
- Step-aware proof capability diagnostics distinguish supported paths from parent-specific boundaries.
- No theorem replay or artifact replay skips are present.
- Proof capability boundaries are documented, especially binder paths, type-changing paths, `EqRec.motive`, and non-definitional `Refl.value`.

## Validation commands

```bash
mix ci
mix docs
mix theoria.lean.check
mix hex.build
mix run examples/kernel_reports/run.exs
mix run examples/simp_capabilities/run.exs
mix run examples/proof_simp_trace/run.exs
rm -f theoria-0.6.0-dev.tar
```

## Current expected highlights

```text
✓ generated term checks: 1408
✓ generated artifact checks: 38
✓ indexed artifact checks: 2
- theorem replay skipped: 0
- artifact replay skipped: 0
```

Lean oracle should remain contributor-only and outside the trusted runtime path.
