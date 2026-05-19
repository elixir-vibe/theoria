# Kernel assurance

Theoria's trusted runtime boundary is the native kernel. Assurance commands compare that kernel with independent reference paths, re-admit checked environments through replay, and check generated artifacts. These checks improve confidence; they are not a formal proof of kernel correctness and do not imply Lean feature parity.

## Main command

```bash
mix theoria.kernel.check
```

This runs the curated kernel corpus, generated terms, generated environment corpora, theorem-module replay, artifact replay, trusted-adjacent metadata/reduction replay, and invalid-environment rejection checks.

Useful variants:

```bash
mix theoria.kernel.check --verbose
mix theoria.kernel.check --coverage
mix theoria.kernel.check --assurance-summary
mix theoria.kernel.check --assurance-summary --coverage
mix theoria.kernel.check --json
```

## Bounds

Generated assurance is bounded so CI remains fast:

```bash
mix theoria.kernel.check --generated-size 1 --generated-max-terms 4
mix theoria.kernel.check --environment-depth 8
```

Defaults are chosen for regular CI. Increase bounds locally for deeper assurance.

## What the counts mean

- Curated corpus: hand-authored infer/check/normalize/defeq/rejection cases.
- Generated terms: deterministic typed terms checked against production and reference paths.
- Environment corpus: generated declaration chains replayed and normalized through production/reference paths.
- Invalid environments: malformed environments rejected with expected reason classes.
- Metadata replay: replayed declarations preserve trusted-adjacent environment metadata and reduction data. This is analogous in spirit to checking Lean environment-extension data, but it is Theoria-specific assurance, not Lean compatibility.
- Artifact replay: generated and indexed equation artifacts replay in checked environments.

## Summary output

```bash
mix theoria.kernel.check --assurance-summary
```

prints a concise user-facing coverage summary. With `--json`, the output is backed by Jason-encoded structs.

## Lean oracle

Contributor-only Lean validation remains separate:

```bash
mix theoria.lean.check
```

Lean is an external regression oracle, not part of Theoria's trusted runtime path.
