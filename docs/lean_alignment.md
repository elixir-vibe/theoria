# Lean alignment notes

This table tracks Theoria's proof/equation abstractions against the Lean 4 source architecture. Lean is a contributor-only oracle for Theoria, not a runtime dependency or source of truth.

| Lean abstraction | Lean role | Theoria abstraction | Status | Missing on Theoria side |
|---|---|---|---:|---|
| `PreDefinition` | Not-yet-finalized definition package | `Equation.DefinitionSpec`, `Equation.Signature` | 🟡 | No mutual predefinition groups, equation-affecting options, termination data, or elaborator-owned predefinition pipeline. |
| `Structural.EqnInfo` | Stores recursive equation metadata: declaration, levels, type/value, rec arg, fixed params | `Equation.Info` | 🟢 | Fixed params are parameter positions, not full permutations. No recursion kind or mutual group metadata. |
| `FixedParamPerms` | Computes fixed/varying params across recursive groups | `Equation.FixedParams` | 🟡 | Signature-level fixed parameter derivation exists, but no permutations, dependency analysis, or mutual recursion support. |
| `MatcherInfo` / `AltParamInfo` | Matcher arity, params, discriminants, alternatives, universe elimination, overlaps | `Equation.MatcherInfo`, `Equation.MatcherSpec`, `Env.Matcher` | 🟡 | Checked matcher declarations exist, but matcher type/value are source-aligned placeholders, not true matcher arity; no discriminant dependency analysis or universe-elim sophistication. |
| `mkEqnTypes` / `mkEqns` | Computes equation theorem statements and realizes proofs | `SchemaBuilder`, `Equation.Lemma`, `Eqns` | 🟡 | Current generated equations are template-driven for supported fragments, not derived by splitting normalized match goals. |
| `getEqnsFor?` / `registerGetEqnsFn` | Lazy central lookup for equation theorem names | `Equation.Eqns`, `Equation.Extension` | 🟡 | Lazy realization APIs exist, but there is no persistent lazy theorem registry; source lookup is derived by scanning typed metadata. |
| `mkUnfoldEq` / `getUnfoldFor?` | Unfold equation theorem generation | `Eqns.unfold/2`, `Lemma.unfold_for/1` | 🟡 | Early direct unfold lemmas only; no separate lazy unfold theorem registry. |
| `MatchEqsExt` | Matcher-specific equation theorem extension | `MatcherEquation`, `MatcherEqns`, `Env.Matcher` | 🟡 | Matcher equations are schema-derived and theorem-checkable, but there is no persistent matcher equation extension or independently compiled matcher body yet. |
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

The main remaining Lean-alignment target is to replace template-driven equation generation with equation type generation from matcher/definition structure, then add independently compiled matcher bodies, richer fixed-parameter permutations, and a persistent lazy theorem registry.
