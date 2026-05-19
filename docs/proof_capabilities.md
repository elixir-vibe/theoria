# Proof capabilities

Theoria's rewrite and simp engines are untrusted search/construction helpers. A proof-producing step is accepted only when the generated core proof checks with the native kernel.

Capability reports describe which structural paths currently have proof construction support. The matrix is path-oriented, while actual rewrite-step diagnostics are parent-term aware.

## Supported paths

| Path | Capability | Notes |
|---|---|---|
| `[]` | `:top_level` | Uses the rule proof directly. |
| `[:arg]`, `[:fun]` | `:application_congruence` | Application congruence. Nested application paths are supported when every segment is `:arg` or `:fun`. |
| `[:left]`, `[:right]` | `:equality_side` | Equality-side transport. |
| `[:base]` | `:eq_rec_base_congruence` | `EqRec` base congruence. |
| `[:proof]` | `:eq_rec_proof_congruence` | `EqRec` proof congruence; this does not assume proof irrelevance. |
| `[:base, ...]`, `[:proof, ...]` | outer `EqRec` capability with `inner` | Supported when the nested path is itself supported. |
| `[:value]` | `:value_congruence` | Step-aware support for implemented constructor-value transports, currently `let` values. |

Nested capability JSON may contain an `inner` capability:

```json
{
  "supported": true,
  "reason": "eq_rec_base_congruence",
  "description": "EqRec base congruence",
  "inner": {
    "supported": true,
    "reason": "application_congruence",
    "description": "application congruence",
    "inner": null
  }
}
```

## Current boundaries

| Path | Boundary |
|---|---|
| `[:domain]`, `[:body]` | Binder paths need context-sensitive transport. |
| `[:type]` under equality/let/EqRec | Type-changing transport is not generalized yet. |
| `[:motive]` under `EqRec` | Motive transport is not supported. |
| non-definitional `Refl.value` | Reported as `:refl_value_boundary`; homogeneous equality alone is not enough to rewrite proof types safely without stronger typed transport. |

Unsupported paths are deliberate boundaries, not trusted failures. The caller can still inspect the rewritten term, but no proof is trusted unless `Theoria.Kernel.check/3` accepts it.

## CLI

```bash
mix theoria.simp --capabilities
mix theoria.simp --capabilities --json
```

`Theoria.Simp.Result.proof_status_counts/1` summarizes checked/missing/unsupported step proofs for a simplification trace.
