# Roadmap

Theoria's post-0.8 direction is Elixir-centric: make Theoria the native trust kernel for tool- and agent-generated claims, not a Lean replacement and not a general verifier for arbitrary Elixir programs.

## Guiding principle

```text
Elixir tools produce facts and obligations.
Theoria checks the proof/certificate artifacts for selected claims.
```

Theoria should favor small, replayable certificates over large domain-specific proof libraries unless a concrete Elixir use case demands them.

## 0.9 — obligations and certificates

Status: started in `0.9.0-dev` with the initial `Theoria.Obligation`, `Theoria.Certificate`, and `Theoria.Certificate.Report` structs.

Add a generic checked-claim layer:

```elixir
Theoria.Obligation
Theoria.Certificate
Theoria.Certificate.Report
```

Goals:

- represent tool-generated claims with assumptions, goals, witnesses, and optional proofs;
- check obligations through the native kernel;
- replay certificates against an environment;
- emit structured JSON diagnostics for CI and agent reports.

## 0.10 — Elixir typespec facts

Status: initial extractor started in `0.9.0-dev` with `Theoria.Typespec`, `Contract`, `Type`, `Report`, and `mix theoria.typespecs` for common Elixir typespec fragments.

Normalize Elixir typespecs into Theoria-friendly contract data:

```elixir
Theoria.Typespec
Theoria.Typespec.Contract
Theoria.Typespec.Type
Theoria.Typespec.Report
```

Initial subset:

- `term`, `atom`, `boolean`;
- `integer`, `non_neg_integer`;
- `String.t()`;
- lists;
- tuples and tagged tuples;
- unions;
- structs.

Typespecs are not trusted proofs. They are Elixir-native contract declarations that can drive obligations, rewrite preconditions, API compatibility checks, Reach fact annotations, and Vibe safety reports.

## 0.11 — generic spec vocabulary

Status: initial finite-set, graph path, effect lattice, and typespec compatibility vocabularies started in `0.9.0-dev` with `Theoria.Spec.Finite`, `Theoria.Spec.Graph`, `Theoria.Spec.Effect`, and `Theoria.Spec.Typespec`.

Add small reusable claim families for tool-generated facts:

```elixir
Theoria.Spec.Finite
Theoria.Spec.Graph
Theoria.Spec.Effect
Theoria.Spec.Rewrite
Theoria.Spec.Typespec
```

Initial claims:

- finite membership/subset checks;
- graph path witness validity;
- node/edge existence;
- all edges allowed by a policy;
- no-new-effects/effect-lattice claims;
- rewrite rule instance validity;
- declared return shape preserved.

## 0.12 — Reach integration

Reach computes program facts; Theoria checks selected claims over those facts.

Target API shape in Reach:

```elixir
Reach.Theoria.obligations(report)
Reach.Theoria.check(report)
```

Start with:

- dependency path witnesses;
- no-new-effects/effect delta claims;
- architecture boundary claims;
- unreachable/dead-code witnesses;
- plugin fact validation.

## 0.13 — ex_ast and rewrite integration

Make structured rewrites certificate-aware:

```elixir
ExAST.Theoria.rewrite_obligation(before, after, rule)
```

Start with syntactic rewrite witnesses and a small set of semantic rewrite rules whose preconditions can be checked from typespec/Reach facts.

## 0.14 — Vibe integration

Expose Theoria certificates in agent-facing change reports:

```elixir
%Vibe.ChangeReport{
  static_checks: ...,
  reach_claims: ...,
  certificates: ...
}
```

Reports should distinguish:

```text
heuristic
statically checked
Theoria kernel checked
unchecked
```

## Later — proof ergonomics and libraries

Add richer tactics, proof-state tooling, finite maps/sets, arithmetic, bitvectors, or larger libraries only when real obligations require them. The near-term priority is tool integration and certificate replay, not recreating Lean's library stack.
