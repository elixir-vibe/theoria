# 0.7 development boundary

The 0.7 line focuses on deeper kernel/reference assurance through environment replay diagnostics and generated declaration environments.

## Replay diagnostics

0.7 should make replay failures actionable. Reference replay failures carry structured data such as declaration name, phase, declaration kind, direct dependencies, transitive dependencies, missing dependencies, and details. Further work should enrich this with production/reference details where relevant.

## Environment assurance

0.7 expands beyond replaying the Prelude and generated theorem environments. Candidate environment corpora include:

- explicit axiom environments;
- transparent/opaque definition chains;
- theorem dependencies over generated declarations;
- universe-polymorphic declaration fragments;
- intentionally rejected malformed variants for regression tests.

## Declaration-chain generation

0.7 should generate bounded declaration chains and compare production/reference behavior for declaration admission, replay, normalization, and dependency tracking.

## Boundaries

This is still assurance, not a formal proof of kernel correctness. The trusted runtime boundary remains native kernel checking of declarations and artifacts. Lean remains an optional contributor oracle outside the trusted runtime path.
