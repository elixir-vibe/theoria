# Changelog

## Unreleased

Post-0.7 development toward public DSL and equation API stabilization.

- Added 0.8 API stabilization boundary docs and public API stability guide.
- Added a theorem module example and wired public examples into tests.
- Added `Theoria.Equation` facade helpers for registry summary, identities, and theorem realization.
- Made experimental pre-1.0 module docs version-neutral.
- Added assurance summary accessors and extended downstream smoke coverage for installed theorem modules and assurance JSON.

## 0.7.0

Kernel/reference assurance depth, replay diagnostics, and downstream smoke coverage.

- Added structured reference replay diagnostics with declaration phase, kind, dependency context, dependency path, replay order, and pending declarations.
- Added deterministic environment assurance for declaration, let, theorem, and universe-polymorphic chains with configurable `--environment-depth`.
- Added invalid environment rejection assurance with expected reasons for malformed indexes, bad declaration values, bad theorem proofs, duplicate declarations, and unknown dependencies.
- Added structured metadata/reduction replay reports with source breakdowns for Prelude, generated environments, generated artifacts, indexed artifacts, and theorem modules.
- Added `Theoria.Kernel.AssuranceSummary`, kernel/validation corpus summary structs, `docs/assurance.md`, and `mix theoria.kernel.check --assurance-summary` with coverage/JSON support.
- Improved `mix theoria.theorems MODULE` to load downstream theorem modules directly.
- Added downstream Mix project smoke coverage and package file boundary checks.

## 0.6.0

Proof-producing rewrite expansion and structured generated assurance reports.

- Added an experimental deterministic typed generator module and wired generated-term checks into kernel differential reports.
- Added kernel-checked proof lifting for `EqRec` base/proof rewrite paths, including supported nested paths.
- Added kernel-checked proof lifting for supported constructor value rewrite paths, including `let` values.
- Equality chains now bridge missing definitional-equality steps when composing explicit checked proofs.
- Kernel differential reports now include structured generated-term reports with configurable bounds, timing, diagnostics, and family counts.
- Generated-term assurance now covers deterministic `let`, `forall`, Bool equality, and Bool/Nat beta families.
- Proof capability JSON can expose nested `inner` capabilities for composed structural lifts.
- Simp results now expose proof status counts for trace reports.
- Kernel differential reports now summarize generated artifact proof strategies with a structured proof-strategy report.
- Proof capabilities now include step-aware diagnostics for parent-specific boundaries such as `Refl.value` and type-changing paths.

## 0.5.0

Structured assurance reports, proof diagnostics, and theorem/artifact replay.

### Added

- Added structured kernel assurance reports with reference replay, theorem-module replay, generated/indexed artifact replay, coverage, explanation, and timing metadata.
- Added `mix theoria.kernel.check --coverage`, `--explain`, and richer JSON output backed by Jason encoders.
- Added proof capability reporting through `Theoria.Rewrite.Proof.Capabilities`, `mix theoria.simp --explain`, and `mix theoria.simp --capabilities`.
- Added structured proof diagnostics via `Theoria.Rewrite.Proof.Result` and proof capability structs.
- Added equality-chain proof strategy metadata and direct simp result proof accessors.
- Added explicit universe constraint sets, solver explanations, and a symbolic regression matrix.
- Added theorem-module, artifact replay, kernel explanation, timing, and proof capability report structs.
- Added typed generated-term property coverage and direct `EqRec` reference normalization tests.
- Added examples for kernel reports and simp capabilities.
- Added `docs/reports.md` and `docs/release_0_5.md`.

### Changed

- Replaced separate rewrite/simp step proof fields with a structured `proof_result`.
- Split term quote and Prelude-specific quote sugar out of the main DSL facade.
- Extracted constant/axiom, theorem, definition, matcher, and inductive admission boundaries from the main kernel module.
- Fixed universe-parameter installation for polymorphic generated artifacts.
- Extended proof-producing rewrite support to nested application paths and selected equality-side paths.
- Made binder and `EqRec` proof-path boundaries explicit through capability reporting and tests.

### Validation

- Kernel differential checks now include theorem-module-installed environment replay and generated/indexed artifact environment replay.
- Reference properties now cover typed dependent fragments and `EqRec` over reflexivity.
- Native validation, docs, Dialyzer, Credo, ExDNA, Reach checks, tests, and Lean oracle validation remain clean.
## 0.4.0

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
