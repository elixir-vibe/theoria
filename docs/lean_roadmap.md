# Lean-inspired roadmap

This document tracks which Lean ideas Theoria has already adapted and which ones are worth building next. It is not a plan to port all of Lean. Theoria should remain Elixir-native and keep the trusted kernel small.

Legend:

| Status | Meaning |
|---|---|
| ✅ | implemented enough for current Theoria |
| 🟡 | partially implemented |
| 🔴 | missing and important |
| ⚪ | intentionally postponed / maybe later |
| ❌ | probably should not port directly |

## Core trusted kernel / expressions

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| `Expr.sort` | Universe sort term | ✅ | `%Term.Sort{level}` | Keep hardening universe solver | P0 |
| `Expr.const` with universe levels | Named constant with level args | ✅ | `%Term.Const{name, levels}` | Add better level inference later | P0 |
| `Expr.app` | Function application | ✅ | `%Term.App{}` | Stable | P0 |
| `Expr.lam` | Lambda abstraction | ✅ | `%Term.Lam{}` | Stable | P0 |
| `Expr.forallE` | Dependent function type | ✅ | `%Term.Forall{}` | Stable | P0 |
| `Expr.letE` | Local definitions / zeta | ✅ | `%Term.Let{}` with zeta reduction | Stable | P0 |
| `Expr.bvar` | De Bruijn variables | ✅ | `%Term.BVar{}` | Stable | P0 |
| `Expr.fvar`, `Expr.mvar` | Free/meta variables for elaboration | ❌ | No kernel metavars | Add elaborator-only holes/metavars later, not kernel first | P3 |
| Literal support | Nat/string literals | ❌ | No primitive literals | Add through inductive/library encodings later | P4 |
| Projection expressions | Structure field projections | ❌ | No structures yet | Wait until structures/records exist | P4 |
| Term hashing / sharing | Performance | ❌ | Plain structs | Add after benchmarks show need | P4 |

## Universe levels

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| `Level.zero` | `Prop` / lowest universe | ✅ | `%Level.Zero{}` | Stable | P0 |
| `Level.succ` | `Type (u+1)` | ✅ | `%Level.Succ{}` | Stable | P0 |
| `Level.max` | Universe max | ✅ | `%Level.Max{}` | Solver improving | P0 |
| `Level.param` | Universe polymorphism | ✅ | `%Level.Param{}` | Stable | P0 |
| Level normalization | Canonicalize universe exprs | 🟡 | Basic normalization | Add more simplification laws | P1 |
| Universe constraint solver | Decide `u ≤ max u v`, etc. | 🟡 | `Theoria.Level.Solver` groundwork | Expand solver with constraints, substitutions, diagnostics | P0 |
| Universe metavariables | Elaborator inference | ❌ | None | Add later for implicit universe inference | P3 |
| Cumulative universes | Sort/subsort checking | 🟡 | Sort typing exists; limited `leq?` | Formalize cumulativity in checking | P1 |
| `Prop` impredicativity | Lean's Prop behavior | 🟡 | Prop-valued forall rule added | Audit against intended theory | P1 |

## Environment and declarations

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| `Environment` | Stores constants/declarations | ✅ | `%Theoria.Env{}` | Stable enough | P0 |
| `ConstantInfo` | Declaration metadata | 🟡 | `%Env.Constant{}` plus metadata | Continue typed metadata expansion | P0 |
| `DefinitionVal` | Reducible definition | ✅ | `kind: :definition`, `value`, `reducible?` | Stable | P0 |
| `TheoremVal` | Opaque proof declaration | ✅ | `kind: :theorem` | Stable | P0 |
| `AxiomVal` | Trusted assumption | ✅ | `kind: :axiom`; axiom tracking | Stable | P0 |
| `OpaqueVal` | Opaque constants | 🟡 | Theorems/axioms opaque; constants no value | Maybe explicit opacity API | P2 |
| Declaration replay | Validate env integrity | ✅ | `Theoria.Kernel.validate_env/1` | Keep adding corruption tests | P0 |
| Declaration dependency graph | Track dependencies | ✅ | `dependencies/2`, transitive deps | Add hashing/artifacts later | P2 |
| Trust reports | Show axioms/trusted deps | ✅ | `%TrustReport{}` | Improve pretty/docs | P2 |
| Declaration hashing | Reproducibility/cache | ❌ | None | Needed for artifacts/caching | P3 |
| Persistent env extensions | Extensible metadata | ❌ | Hardcoded metadata fields | Maybe plugin-style metadata later | P4 |

## Type checking and definitional equality

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| Type inference | Infer term types | ✅ | `Kernel.infer/2,3` | Keep property testing | P0 |
| Type checking | Check against expected type | ✅ | `Kernel.check/3,4` | Improve cumulativity | P0 |
| WHNF | Weak-head normalization | ✅ | `Normalize.whnf/2` | More tests/fuel | P0 |
| Full normalization | Normalize terms | ✅ | `Normalize.normalize/2` | Performance later | P1 |
| Beta reduction | `(λ x => t) a` | ✅ | Implemented | Stable | P0 |
| Delta reduction | Definitions unfold | ✅ | Reducible definitions unfold | Add opacity controls later | P1 |
| Zeta reduction | `let` unfolds | ✅ | Implemented | Stable | P0 |
| Iota reduction | Recursor computation | 🟡 | Simple and basic indexed recursors via `%Reduction.Iota{}` and rules | Harden dependent indexed cases | P0 |
| Eta reduction | Function eta | ❌ | Not supported | Decide explicitly; likely postpone | P3 |
| Proof irrelevance | Lean Prop proof irrelevance | ❌ | Not implemented | Decide theory first | P4 |
| Quotient reduction | Lean quotient kernel support | ❌ | None | Probably postpone/avoid | P5 |
| Fuel/termination control | Avoid nontermination | 🟡 | Fuel module exists | Add stronger stuck/error diagnostics | P1 |
| Defeq properties | Equivalence properties | 🟡 | Some tests | Add property-based well-typed term tests | P1 |

## Inductive declarations

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| `InductiveVal` | Metadata for type former | ✅ | `%Env.Inductive{}` | Add mutual/nested fields later | P0 |
| `ConstructorVal` | Metadata for constructors | ✅ | `%Env.Constructor{}` | Stable | P0 |
| `RecursorVal` | Metadata for recursors | 🟡 | `%Env.Recursor{}` for simple and indexed recursors | Harden indexed validation | P0 |
| `RecursorRule` | Iota rule metadata | 🟡 | `%Env.RecursorRule{constructor, field_count, rhs, index_patterns}` with constructor-index validation | Full dependent codomain validation | P0 |
| Inductive admission pipeline | Kernel checks inductive declarations | 🟡 | `Inductive.Admission` staged path | Move more ownership here; more Lean checks | P0 |
| Strict positivity | Reject negative recursive occurrences | 🟡 | Basic positivity check | Harden nested/mutual cases | P0 |
| Constructor target checks | Constructors return the family | ✅ | Implemented | Stable | P0 |
| Parameter preservation | Constructors preserve params | ✅ | Implemented | Stable | P0 |
| Index arity checks | Indexed result has correct args | ✅ | Implemented | Stable | P0 |
| Recursive index occurrence rejection | Lean-inspired safety | ✅ | Added | Stable | P0 |
| Constructor universe checks | Field universe ≤ result universe or Prop | 🟡 | Initial check | Improve with solver | P0 |
| Generated recursors | Auto rec/ind generation | 🟡 | Bool/Nat/List simple recursors and Vec indexed recursor | Harden arbitrary indexed cases | P0 |
| Recursor RHS typing | Rules type-infer as expected shape | 🟡 | Type shape validation added | Full dependent result validation later | P0 |
| Indexed inductives | Families like `Vec A n` | 🟡 | Vec-style families admit constructors and generated eliminators | Harden dependent validation | P0 |
| Indexed eliminators | `Vec.ind` | 🟡 | Recursors with validated rules/index patterns and basic iota | Harden dependent validation | P0 |
| Indexed iota reduction | Computation for indexed recursors | 🟡 | Basic Vec library iota reduction with constructor-index validation | Harden dependent codomains | P0 |
| Mutual inductives | `mutual Even/Odd` | 🔴 | Missing | Add `Inductive.Group` later | P2 |
| Nested inductives | Recursive occurrence under containers | 🔴 | Mostly rejected/unsupported | Later after positivity overhaul | P3 |
| Quotient inductives | Lean-specific quotient support | ❌ | None | Probably do not port early | P5 |
| No-confusion principles | Constructor disjointness/injectivity | 🔴 | Missing | Generate later for inductives | P2 |
| Below/brecOn recursors | Course-of-values recursion | ❌ | Missing | Maybe never / much later | P5 |

## Built-in libraries / prelude

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| Prelude env | Standard declarations | ✅ | `Theoria.Prelude.env/0` | Expand cautiously | P0 |
| `Bool` | Computational bool | ✅ | Inductive Bool with rec/ind | Stable | P0 |
| `Nat` | Natural numbers | ✅ | Inductive Nat with rec/ind/add | Expand theorem corpus | P0 |
| `List` | Lists | ✅ | Inductive List with rec/ind/length | Add append/map/member | P1 |
| `True` / `False` | Logical constants | ✅ | Library declarations | Might later encode inductively | P1 |
| `And` | Conjunction | ✅ | Library declarations/theorems | Maybe inductive later | P1 |
| `Not` | Negation | ✅ | Definition | Stable | P1 |
| `Or` | Disjunction | 🔴 | Missing | Add as inductive | P1 |
| `Exists` | Existential | 🔴 | Missing | Needs Sigma/dependent pair | P1 |
| `Iff` | Logical equivalence | 🔴 | Missing | Add after And/Imp basics | P2 |
| `Prod` | Product type | 🔴 | Missing | Add as inductive/structure | P1 |
| `Sigma` | Dependent pair | 🔴 | Missing | Add after indexed eliminators stronger | P1 |
| `Option` | Optional values | 🔴 | Missing | Easy inductive after library cleanup | P2 |
| `Sum` / Either | Disjoint union | 🔴 | Missing | Easy inductive | P2 |
| `Fin` | Bounded naturals | 🔴 | Missing | Needs indexed families | P2 |
| `Vec` | Length-indexed list | ✅ / 🟡 | `Theoria.Library.Vec` with indexed `vec_ind` reduction and theorem corpus | Expand theorem corpus | P1 |
| Decidable propositions | Computable decisions | 🔴 | Missing | Needed for automation/specs | P2 |
| Finite maps/sets | Program/spec library | 🔴 | Missing | Needed before Reach integration | P3 |

## Equality

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| `Eq` | Propositional equality | ✅ / 🟡 | Primitive `%Term.Eq{}` | Decide long-term primitive vs inductive | P0 |
| `Eq.refl` | Reflexivity proof | ✅ | Primitive `%Term.Refl{}` | Stable for now | P0 |
| `Eq.rec` / equality eliminator | Rewrite/substitution principle | 🔴 | Missing | Add primitive or via indexed inductive | P0 |
| `Eq.ndrec` | Nondependent equality recursor | 🔴 | Missing | After Eq.rec | P1 |
| Rewrite theorem support | Rewrite by equality | 🔴 | Missing | Needed for tactics/simp | P1 |
| Congruence lemmas | Function/application congruence | 🔴 | Missing | Needed for rewriting | P2 |
| UIP / proof irrelevance decisions | Equality proof behavior | ⚪ | Not decided | Decide theory later | P4 |
| Eq as indexed inductive | Lean-like equality encoding | ⚪ | Not yet | Revisit after indexed iota | P2 |

## Recursors, eliminators, and computation

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| Nondependent recursor | `Nat.rec`, `List.rec` | ✅ | Generated for simple types | Stable-ish | P0 |
| Dependent induction principle | `Nat.ind`, `List.ind` | ✅ | Generated for simple types | Stable-ish | P0 |
| Recursor major index | Locate major premise | ✅ | `Env.Recursor.major_index/1` | Extend for indexed families | P0 |
| Iota rules from metadata | Rule-based computation | ✅ / 🟡 | Simple families and basic indexed families | Harden indexed validation | P0 |
| Recursor rule RHS authoritative | Normalizer uses RHS | ✅ | Implemented | Continue validation | P0 |
| Rule type shape validation | Reject wrong domains/extra lambdas | ✅ / 🟡 | Added structural validation | Full dependent codomain validation later | P0 |
| Indexed recursor declarations | `Vec.ind` declaration | 🟡 | Iota declarations generated with rule metadata | Harden indexed validation | P0 |
| Indexed recursor iota | Computation over `Vec` | 🟡 | Basic index-pattern-checked reduction | Harden dependent cases | P0 |
| No-confusion recursors | Constructor discrimination | 🔴 | Missing | Later | P2 |
| Recursor compilation to efficient dispatch | Performance | ❌ | Simple list lookup | Optimize later | P4 |

## Elaborator and syntax

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| Named syntax → core elaboration | User syntax to de Bruijn terms | ✅ | `Theoria.Syntax`, `Elaborator` | Stable basic layer | P0 |
| DSL quote | Ergonomic term syntax | ✅ | `term do ... end` | Stable enough | P0 |
| Universe syntax | `sort(u)`, `const(:List, [u])` | ✅ | Implemented | Stable | P0 |
| Interpolation | Embed dynamic terms/levels/names | ✅ | `^` support | Stable | P0 |
| Theorem macro | Declare theorem modules | ✅ | `theorem` macro | Improve proof ergonomics later | P1 |
| Expected-type elaboration | Infer omitted info from expected type | 🔴 | Missing | Needed for tactics/sugar | P2 |
| Implicit arguments | Lean-style `{α}` / inference | 🔴 | Missing | Later, after kernel stable | P3 |
| Universe inference | Avoid explicit levels | 🔴 | Missing | Needs universe metavars/solver | P3 |
| Holes/metavariables | Interactive proof construction | 🔴 | Missing | Needed for tactics | P2 |
| Source spans | Better errors | 🔴 | Missing | Add to syntax/errors | P2 |
| Parser-like notation extensibility | Lean syntax macros | ❌ | Elixir macros only | Do not port Lean parser architecture | P5 |

## Theorem management and proof checking

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| Theorem declarations | Store checked proofs | ✅ | `Theoria.Theorem` | Stable | P0 |
| Opaque theorem values | Theorems do not reduce | ✅ | `kind: :theorem`, `reducible?: false` | Stable | P0 |
| Theorem module registry | Check all theorems | ✅ | `__theoria_theorems__/0` | Stable | P0 |
| Axiom tracking | Trust boundary | ✅ | `axioms/2`, trust report | Stable | P0 |
| Theorem checking Mix task | CI checker | ✅ | `mix theoria.check` | Stable | P0 |
| Theorem corpus | Regression proofs | ✅ | 45 theorem(s) | Expand libraries | P1 |
| Proof irrelevance for theorem proofs | Lean Prop behavior | ❌ | None | Decide theory later | P4 |
| Proof artifact serialization | Cache/share proofs | 🔴 | Missing | Add before larger corpora | P3 |
| Incremental proof checking | Avoid checking everything | 🔴 | Missing | After env hashing | P3 |

## Tactics and automation

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| Tactic state/goals | Interactive proof engine | 🔴 | Missing | Add untrusted proof-state layer | P2 |
| `intro` | Introduce forall/implication | 🔴 | Missing | First tactic milestone | P2 |
| `exact` | Close goal with term | 🔴 | Missing | First tactic milestone | P2 |
| `assumption` | Find local hypothesis | 🔴 | Missing | First tactic milestone | P2 |
| `apply` | Backward reasoning | 🔴 | Missing | After holes/metavars | P2 |
| `constructor` | Use constructor/introduction rule | 🔴 | Missing | After inductive APIs mature | P2 |
| `cases` | Case split | 🔴 | Missing | Needs eliminator usage | P2 |
| `induction` | Induction tactic | 🔴 | Missing | Needs robust recursors | P2 |
| `rewrite` / `rw` | Rewrite by equality | 🔴 | Missing | Needs Eq recursor | P2 |
| `simp` | Simplifier | 🔴 | Missing | Needs rewrite database | P3 |
| `omega` / arithmetic solvers | Automation | ❌ | Missing | Much later / maybe not | P5 |
| Metaprogramming framework | Lean tactic language | ❌ | Missing | Do not port Lean meta system directly | P5 |

## Equation compiler / pattern matching

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| Pattern matching compiler | Compile equations to recursors | 🔴 | Missing | Add after recursors/equality stronger | P1 |
| Structural recursion | Termination by smaller argument | 🔴 | Missing | Start with Nat/List primitive recursion | P1 |
| Termination checker | Ensure recursive definitions terminate | 🔴 | Missing | Start conservative | P2 |
| Equation lemmas | Generated simplification theorems | 🔴 | Missing | Needed for `simp` | P2 |
| Dependent pattern matching | Match indexed families | 🔴 | Missing | After indexed iota | P2 |
| Inaccessible patterns | Lean dependent matching feature | ❌ / later | Missing | Probably much later | P5 |
| Partial functions | Lean has partial support | ❌ | Missing | Avoid early; kernel should stay total | P5 |

## Structures, classes, namespaces

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| Structures / records | Product-like named fields | 🔴 | Missing | Could encode via Sigma/Prod first | P3 |
| Projections | Field accessors | 🔴 | Missing | After structures | P3 |
| Typeclasses | Instance search | ❌ | Missing | Not needed early | P5 |
| Namespaces | Organize declarations | 🟡 | Atom/module names only | Maybe add name module later | P3 |
| Attributes | Mark simp/rewrite/etc. | 🔴 | Missing | Needed for simplifier later | P3 |
| Sections/variables | Lean source convenience | ❌ | Missing | Elixir DSL can handle differently | P5 |

## Modules, compilation, artifacts

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| Import system | Load modules/envs | 🟡 | Elixir modules/prelude | Add serialized env imports later | P3 |
| `.olean` artifacts | Compiled environment artifacts | ❌ | None | Add theorem/env artifacts later | P3 |
| Environment hashes | Reproducibility/cache | ❌ | None | Add before large libraries | P3 |
| Module-level trust reports | Audit imports | 🟡 | Theorem trust reports | Extend to artifacts | P3 |
| Incremental checking | Fast rebuilds | ❌ | Full check currently | Later | P4 |

## Diagnostics and developer experience

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| Pretty printer | Human-readable terms | ✅ | `Theoria.Pretty` / `Inspect` | Keep improving | P1 |
| Kernel error structs | Structured errors | ✅ | `%Theoria.Error{}` | Add richer context | P1 |
| Elaborator errors | User-level diagnostics | 🟡 | Basic pretty errors | Add source spans/named contexts | P2 |
| Defeq mismatch diff | Explain type mismatch | 🔴 | Basic left/right | Add normalized diff | P2 |
| Trace/debug normalization | Inspect reductions | 🔴 | Missing | Useful soon | P2 |
| Docs generation | ExDoc | ✅ | Docs integrated | Continue | P1 |

## Testing and verification infrastructure

| Lean feature / concept | Lean role | Theoria status | Current Theoria state | Needed roadmap | Priority |
|---|---|---:|---|---|---:|
| Kernel corruption tests | Catch invalid envs | ✅ / 🟡 | Leanchecker-inspired tests | Keep expanding | P0 |
| Theorem corpus tests | Prove library facts | ✅ | 45 theorem(s) | Expand corpus | P1 |
| Property tests for terms | Subst/shift/scope laws | 🟡 | Some properties | Add well-typed generator | P1 |
| Normalization preservation | Reduction preserves type | 🔴 | Missing broadly | Add property tests | P1 |
| Defeq laws | Equivalence properties | 🔴 | Missing broadly | Add generated well-typed tests | P1 |
| Inductive admission fuzzing | Random invalid specs | 🔴 | Missing | Add after APIs stabilize | P2 |
| Real-world spec tests | Consume by Reach/etc. | 🔴 | Missing | Later | P4 |

## Features probably not worth porting soon

| Lean feature | Why not now | Theoria direction |
|---|---|---|
| Lean parser/frontend architecture | Theoria is Elixir-native | Use Elixir macros/DSL |
| Lean tactic metaprogramming system | Huge project by itself | Small untrusted tactic layer |
| Quotients | Complicated kernel feature | Avoid until real need |
| Typeclasses | Powerful but large complexity | Maybe later, not core |
| Elaborator elaboration monad | Lean-specific scale | Small expected-type elaborator |
| Compiler/codegen | Lean compiles programs | Theoria checks specs/proofs, not app code |
| Native arithmetic solvers | Heavy automation | Add only after core proof layer |
| Full mathlib compatibility | Not the goal | Build small Theoria-native library |
| Lean syntax notation framework | Not Elixir idiomatic | DSL helpers/macros |

## Practical milestone roadmap

### Milestone 0 — current state

| Area | Status |
|---|---|
| Kernel terms | ✅ |
| Universes | 🟡 |
| Env declarations | ✅ |
| Bool/Nat/List | ✅ |
| Simple recursors | ✅ |
| Iota via rules | ✅ |
| Inductive metadata | ✅ |
| Indexed family admission | 🟡 |
| Indexed eliminators | 🟡 opaque non-iota |
| Tactics | 🔴 |
| Equation compiler | 🔴 |

### Milestone 1 — finish current inductive foundation

| Step | Deliverable | Priority |
|---|---|---:|
| Generate indexed eliminators | ✅ `Generate.indexed_eliminators/1`; `Vec.ind` declaration with iota metadata | P0 |
| Add indexed recursor metadata without rules | ✅ `%Env.Recursor{num_indices > 0, rules: []}` allowed with `reduction: nil` | P0 |
| Improve indexed induction type checking | ✅ Generated indexed eliminator type kernel-infers after install | P0 |
| Extend docs | Explain indexed eliminators are noncomputational for now | P1 |
| Add tests | Vec-like install + metadata tests | P0 |

### Milestone 2 — indexed iota

| Step | Deliverable | Priority |
|---|---|---:|
| Extend `RecursorRule` | ✅ Add index-pattern metadata | P0 |
| Generate indexed rules | ✅ `Vec.nil`, `Vec.cons` rule metadata | P0 |
| Validate indexed rule types | Full dependent motive/index checking | P0 |
| Normalize indexed recursors | ✅ Reduce `Vec.ind ... vec_nil` / `vec_cons` | P0 |
| Add Vec library | ✅ Real `Theoria.Library.Vec` | P1 |

### Milestone 3 — equality eliminator

| Step | Deliverable | Priority |
|---|---|---:|
| Add `Eq.rec` primitive or declaration | Rewrite principle | P0 |
| Add rewrite helper theorem APIs | Use equality proofs | P1 |
| Decide primitive vs inductive Eq | Architecture decision | P1 |
| Add equality theorem corpus | symmetry, transitivity, congruence | P1 |

### Milestone 4 — equation compiler

| Step | Deliverable | Priority |
|---|---|---:|
| Pattern AST | Constructors/vars/wildcards | P1 |
| Bool/Nat/List equation compiler | Compile to recursors | P1 |
| Generated equation theorems | Computation lemmas | P2 |
| Termination checker v0 | Structural only | P2 |
| Replace hand-written library defs | `nat_add`, `list_length`, etc. | P2 |

### Milestone 5 — proof ergonomics

| Step | Deliverable | Priority |
|---|---|---:|
| Proof state/goals | Untrusted proof engine | P2 |
| `intro`, `exact`, `assumption` | Basic tactics | P2 |
| `apply`, `constructor` | Useful proof automation | P2 |
| `cases`, `induction` | Recursor-backed tactics | P2 |
| `rewrite`, `simp` | Equality-backed automation | P3 |

### Milestone 6 — library growth

| Step | Deliverable | Priority |
|---|---|---:|
| `Or`, `Exists`, `Prod`, `Sigma` | Core logic/data | P1 |
| `Option`, `Sum`, `Fin` | Programming data | P2 |
| Nat order/arithmetic | `≤`, `<`, `+`, `*` facts | P2 |
| List append/map/member | Useful list library | P2 |
| Decidable predicates | Automation/specs | P3 |

### Milestone 7 — specs and Reach integration

| Step | Deliverable | Priority |
|---|---|---:|
| `Theoria.Spec` | Elixir-facing spec layer | P3 |
| Executable property bridge | StreamData/ExUnit integration | P3 |
| Finite graph library | Graph predicates/theorems | P3 |
| Reach invariant specs | CFG/dataflow/effects invariants | P4 |
| Report integration | CI/spec reports | P4 |

## Strategic recommendation

For the next several cycles, prioritize:

```text
1. opaque indexed eliminators
2. indexed recursor metadata
3. indexed iota rules
4. equality eliminator
5. equation compiler
```

Avoid spending much time on tactics or DSL cosmetics until those are done. Theoria's differentiator will be a small, credible kernel, not surface syntax.
