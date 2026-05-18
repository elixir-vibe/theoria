# Changelog

## 0.2.0 - unreleased

Second experimental release after the initial Hex publication.

- Hardened equation/matcher metadata validation and registry checks.
- Added in-memory equation registry snapshots and centralized generated-theorem realization.
- Derived matcher descriptors from checked recursor metadata for the supported Bool/Nat/List fragment.
- Added architecture regression tests for equation/matcher layering.
- Added release-boundary documentation and clearer experimental/internal API labels.

## 0.1.0

Initial experimental release.

- Added a small dependent proof/spec kernel with explicit checked environments.
- Added core terms, normalization, local definitions, universe parameters, equality, and theorem declarations.
- Added theorem modules and Mix tasks for theorem validation and installation workflows.
- Added Logic, Equality, Bool, Nat, List, and Vec libraries with theorem corpora.
- Added inductive specifications, generated recursors/inductors, checked metadata, and iota reduction.
- Added native validation via `mix theoria.check` and `mix theoria.validate`.
- Added contributor-only Lean oracle validation via generated Lean source.
- Added internal equation compiler metadata for supported Bool/Nat/List definitions.
- Added checked matcher declarations, generated ordinary equations, matcher equations, unfold equations, and registry validation.
- Added experimental rewrite and simp groundwork consuming generated equation metadata.
- Added ExDoc guides, CI, Reach architecture checks, Credo, ExDNA, Dialyzer, and docs build validation.
