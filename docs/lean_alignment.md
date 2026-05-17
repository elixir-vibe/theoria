# Lean alignment notes

This table tracks Theoria's proof/equation abstractions against the Lean 4 source architecture. Lean is a contributor-only oracle for Theoria, not a runtime dependency or source of truth.

| Lean abstraction | Lean role | Theoria abstraction | Status | Missing on Theoria side |
|---|---|---|---:|---|
| `PreDefinition` | Not-yet-finalized definition package | `Equation.DefinitionSpec`, `Equation.Signature` | 🟡 | No mutual predefinition groups, equation-affecting options, termination data, or elaborator-owned predefinition pipeline. |
| `Structural.EqnInfo` | Stores recursive equation metadata: declaration, levels, type/value, rec arg, fixed params | `Equation.Info` | 🟢 | Fixed params are positions, not full permutations/analysis. No recursion kind or mutual group metadata. |
| `FixedParamPerms` | Computes fixed/varying params across recursive groups | `Equation.FixedParams` | 🟠 | No analysis, permutations, or mutual recursion support. |
| `MatcherInfo` / `AltParamInfo` | Matcher arity, params, discriminants, alternatives, universe elimination, overlaps | `Equation.MatcherInfo` | 🟡 | No discriminant info, overlap map, independent matcher declarations, or universe-elim sophistication. |
| `mkEqnTypes` / `mkEqns` | Computes equation theorem statements and realizes proofs | `SchemaBuilder`, `Equation.Lemma`, `Eqns` | 🟡 | Current generated equations are template-driven for supported fragments, not derived by splitting normalized match goals. |
| `getEqnsFor?` / `registerGetEqnsFn` | Lazy central lookup for equation theorem names | `Equation.Eqns` | 🟡 | No lazy realization registry; source lookup is derived by scanning metadata. |
| `mkUnfoldEq` / `getUnfoldFor?` | Unfold equation theorem generation | `Eqns.unfold/2`, `Lemma.unfold_for/1` | 🟡 | Early direct unfold lemmas only; no separate lazy unfold theorem registry. |
| `MatchEqsExt` | Matcher-specific equation theorem extension | `MatcherEquation`, `MatchEqns` | 🟡 | Matcher equations are schema-derived and theorem-checkable, but there are no independent matcher declarations or persistent matcher equation extension yet. |
| `brecOn` / below machinery | Structural recursion beyond simple primitive recursors | None | 🔴 | No below dictionaries or general structural recursion checker. |
| Simp theorem DB | Attribute/prioritized proof-producing simplification | `Simp.Rule`, `Simp.Database`, `Simp.Step` | 🟠 | No attributes, indexing, conditional rules, congruence, or proof-producing simplification. |

Current equation flow:

```text
Signature + CaseTemplate + Clause/Pattern
  → SchemaBuilder
  → Compiler
  → Compiled
  → DefinitionSpec
  → Info
  → Eqns
  → Rewrite/Simp
```

The main remaining Lean-alignment target is to replace template-driven equation generation with equation type generation from matcher/definition structure, then add matcher equation extensions and fixed-parameter analysis.
