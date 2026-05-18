# Changelog

## Unreleased

Post-0.3 development toward proof-producing rewrite/simp automation.

- Bumped development version to `0.4.0-dev`.
- Added `Theoria.Equality.Chain` as equality trace realization groundwork.
- Added `Theoria.Simp.Result` and proof-aware `Theoria.Simp.Step` metadata.
- Added `Simp.normalize(..., prove: true)`, `Simp.realize/3`, and `Simp.add_theorem/4` for checked simplification artifacts and explicit theorem installation.

## 0.3.0

Released 2026-05-18.

- Introduced structured `Theoria.Equation.Identity` identities for ordinary, unfold, matcher, and indexed matcher equations.
- Removed generated equation declaration atoms; installed generated equations now use structured `Theoria.Equation.Identity` values as environment keys.
- Added `Theoria.Equation.Realized` so generated equation checking is an anonymous artifact phase before optional theorem installation.
- Added selector-based indexed matcher equation lookup/realization and opt-in Vec indexed equation theorem installation.
- Added indexed matcher equation identity metadata recording in opt-in Vec environments.
- Carried structured equation identities through rewrite/simp rule metadata and friendly CLI/Lean labels.
- Added proof-aware rewrite rule fields for future proof-producing simp traces.
- Split indexed matcher packages into explicit statement, lemma, realization, and installation phases.
- Added explicit indexed matcher rewrite/simp database constructors behind opt-in policy.
- Generated the Lean oracle mirror declaration for the validation Vec matcher from the checked matcher type.

## 0.2.0

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
