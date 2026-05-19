# 0.7 development boundary

The 0.7 line focuses on deeper kernel/reference assurance through environment replay diagnostics and generated declaration environments.

## Replay diagnostics

0.7 should make replay failures actionable. Reference replay failures carry structured data such as declaration name, phase, declaration kind, direct dependencies, transitive dependencies, missing dependencies, dependency path, checked declarations before failure, pending declarations after failure, and details. Further work should enrich this with production/reference details where relevant.

## Environment assurance

0.7 expands beyond replaying the Prelude and generated theorem environments. Candidate environment corpora include:

- explicit axiom environments;
- transparent/opaque definition chains;
- theorem dependencies over generated declarations;
- universe-polymorphic declaration fragments;
- intentionally rejected malformed variants for regression tests.

## Declaration-chain generation

0.7 generates bounded declaration, let, theorem, and universe-polymorphic chains and compares production/reference behavior for replay, normalization, and dependency tracking. `mix theoria.kernel.check --environment-depth N` controls the generated chain depth. Invalid environment cases also check that malformed declaration indexes, bad declaration values, bad theorem proofs, duplicate declaration indexes, and unknown dependencies are rejected by native environment validation with the expected reason.

## Assurance summary

`mix theoria.kernel.check --assurance-summary` prints a user-facing summary of curated corpus, generated term, environment, artifact, theorem, and replay assurance coverage. `--json` returns the same summary through Jason-encoded structs.

## Boundaries

This is still assurance, not a formal proof of kernel correctness. The trusted runtime boundary remains native kernel checking of declarations and artifacts. Lean remains an optional contributor oracle outside the trusted runtime path.
