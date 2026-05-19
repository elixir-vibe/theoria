# 0.6 development boundary

The 0.6 line focuses on deeper proof-producing automation and stronger generated-term assurance.

## Proof path expansion

0.6 explores kernel-checkable proof lifting beyond top-level/application/equality-side paths. Newly supported paths include:

- `EqRec` base paths, including supported nested paths under the base;
- `EqRec` proof paths, including supported nested paths under the proof;

Candidate paths for further work include:

- equality type paths;
- binder domain paths;
- let type/value paths.

No extensionality or proof-irrelevance shortcut is admitted. A path is supported only when the generated proof term checks in the native kernel.

## Equality chains

0.6 should reduce reliance on `:fallback_defeq` by composing explicit checked proofs for multi-step traces where possible. Fallback remains valid only when the final reflexivity proof kernel-checks.

## Generated-term assurance

0.6 starts a typed generator layer for kernel/reference differentials. Generated terms are deterministic and dependency-free so native assurance reports can run them outside test-only property tooling. The goal is to generate terms together with expected types and environments, including dependent functions, equality, `EqRec`, and recursor fragments.

## Reports and examples

0.5 made report/capability APIs structured. 0.6 uses those APIs to explain newly supported proof paths and to document boundaries when proof construction remains unsupported.
