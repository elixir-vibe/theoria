# Changelog

## Unreleased

Post-0.4 development toward stronger kernel assurance and deeper proof automation.

- Added reference environment replay checks to `mix theoria.kernel.check`.
- Extracted constant/axiom and theorem admission from the main kernel module.
- Added kernel assurance coverage reporting with `mix theoria.kernel.check --coverage`.
- Split term quote and Prelude-specific quote sugar out of the main DSL facade.
- Added an explicit kernel inductive admission boundary.
- Added explicit universe constraint sets and strengthened conservative universe solving.
- Extended proof-producing rewrite support to nested application paths.
- Added typed generated-term property coverage for dependent fragments.
- Added replay checks for environments extended with generated and indexed artifacts.

## 0.4.0

Released 2026-05-18.

Proof-producing rewrite/simp automation and Elixir-authored kernel assurance groundwork.

- Added `Theoria.Equality.Chain` as equality trace realization groundwork.
- Added `Theoria.Simp.Result` and proof-aware `Theoria.Simp.Step` metadata.
- Added `Simp.normalize(..., prove: true)`, `Simp.realize/3`, and `Simp.add_theorem/4` for checked simplification artifacts and explicit theorem installation.
- Added `realize: true` support for generated equation rewrite databases so rules can carry checked source artifacts.
- Added `mix theoria.equations --realize`, `mix theoria.simp --prove`, named simp examples, and example scripts to expose checked artifacts from the CLI and package integration paths.
- Added rewrite-step path and substitution tracking through structural rewrites and wired simp traces to consume rewrite-step metadata.
- Added `Theoria.Rewrite.Proof` for instantiated rule proofs and supported application function/argument congruence lifting.
- Added lazy rewrite-rule realization with `realize: :lazy`.
- Added proof-status diagnostics on rewrite and simp steps.
- Added JSON output for equation realization and simp proof examples.
- Added Elixir-authored kernel spec metadata, a reference checker for core terms, a reference normalizer with reference primitive recursor reductions, Bool/Nat/List/Vec corpus cases, rejection/theorem/generated-artifact/indexed-artifact differential checks, and `mix theoria.kernel.check`.
- Updated equality chains to combine available step proofs with transitivity.
- Added trusted boundary documentation and architecture policy guards for kernel-checked artifacts versus untrusted automation.
- Hardened definitional equality so diagnostic binder names no longer affect de Bruijn alpha-equivalent terms.
- Removed the unsound symbolic universe upper-bound shortcut and normalized universe `max` modulo commutativity/associativity for level equality.
- Avoided atom creation from CLI input in theorem, equation, and simp Mix tasks.
- Extracted definition and matcher declaration admission into trusted-adjacent kernel admission modules.
- Split theorem macro implementation out of the core term-construction DSL facade.
- Named the indexed Vec matcher case frame to isolate fragile de Bruijn positions from the main planning flow.

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
