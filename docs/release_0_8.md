# 0.8 development boundary

The 0.8 line focuses on public DSL and equation API stabilization. The goal is to make Theoria easier and safer to consume as a package while keeping experimental internals clearly marked.

## Goals

- Polish theorem module workflow and downstream usage.
- Clarify public, experimental, and internal API surfaces.
- Provide stable facade helpers for common ordinary equation, unfold identity, summary, and realization workflows.
- Document structured equation identities and generated artifact usage.
- Prefer report accessors in examples and user-facing docs.
- Keep assurance and downstream smoke coverage running as public API guardrails.

## Non-goals

- Lean runtime compatibility or full Lean feature parity.
- A full Lean-style elaborator or tactic framework.
- Freezing matcher lookup/planning or explicit indexed matcher internals as public stable API.
- A formal proof of the Elixir kernel.

## Public API posture

0.8 should clearly separate:

- stable-ish public APIs intended for package users;
- experimental APIs that may change before 1.0;
- internal modules that support implementation and assurance workflows.

The trusted runtime boundary remains the native kernel admission/checking path. DSL, equation generation, rewrite/simp, validation, and Lean oracle tooling remain untrusted helpers whose outputs must be checked by the kernel when trust matters.

## Current 0.8 status

The 0.8 line now has the intended public-facing stabilization pieces in place:

- `Theoria.Equation` facade helpers for summary, ordinary identities, unfold identities, all identities, and realization.
- Structured equation, theorem-module, and simp JSON reports backed by Jason encoders.
- Public report accessors for the new reports and key assurance reports.
- Downstream smoke coverage for theorem module installation and the equation facade.
- Module-doc examples/doctests for equation identities, equation summaries, and report structs.
- Theorem DSL documentation and clearer compile-time errors for malformed declarations.

Remaining work should be release polish and bug fixes unless a concrete public API gap appears.
