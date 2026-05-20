# Obligations, certificates, and spec claims

Theoria's post-0.8 integration layer separates three trust levels:

1. **Facts** — data extracted by Elixir tools such as Reach, ex_ast, or Vibe.
2. **Spec claims** — structural witnesses over those facts, such as valid graph paths or no-new-effect deltas.
3. **Obligations/certificates** — Theoria terms and proofs checked by the native kernel.

Spec claims are useful diagnostics, but they are not kernel proofs by themselves.

## Structural claims

`Theoria.Spec` modules normalize common finite facts:

```elixir
graph = Theoria.Spec.Graph.new([{:controller, :context}, {:context, :repo}])
path = Theoria.Spec.Graph.path_claim(graph, :controller, :repo, [:controller, :context, :repo])

Theoria.Spec.Claim.valid?(path)
#=> true
```

Current vocabularies:

- `Theoria.Spec.Finite` — subset and no-new-member claims.
- `Theoria.Spec.Graph` — finite directed graph path witnesses.
- `Theoria.Spec.Effect` — coarse effect deltas and no-new-effects checks.
- `Theoria.Spec.Typespec` — shallow compatibility over normalized Elixir typespec facts.

Use `mix theoria.spec` to print the built-in structural claim examples:

```bash
mix theoria.spec
mix theoria.spec --json
```

`Theoria.Spec.Report` summarizes any structs implementing `Theoria.Spec.Claim`:

```elixir
report = Theoria.Spec.Report.new([path])
Theoria.Spec.Report.valid(report)
#=> 1
```

## Kernel-checked obligations

`Theoria.Obligation` represents a tool-generated claim with a Theoria goal and optional proof term:

```elixir
goal = Theoria.Term.eq(Theoria.Term.sort(1), Theoria.Term.sort(0), Theoria.Term.sort(0))
proof = Theoria.Term.refl(Theoria.Term.sort(0))
obligation = Theoria.Obligation.new(:sort_refl, goal, proof: proof)

{:ok, certificate} = Theoria.Obligation.check(Theoria.new_env(), obligation)
Theoria.Certificate.checked?(certificate)
#=> true
```

`Theoria.Certificate.replay/2` rechecks the original obligation against an environment. `Theoria.Certificate.Report` summarizes checked, failed, and unchecked certificates.

A valid structural claim can also be attached as the witness for a kernel obligation:

```elixir
claim = Theoria.Spec.Finite.subset_claim([:context], [:context, :schema])
goal = Theoria.Term.eq(Theoria.Term.sort(1), Theoria.Term.sort(0), Theoria.Term.sort(0))
proof = Theoria.Term.refl(Theoria.Term.sort(0))

{:ok, obligation} = Theoria.Spec.obligation(claim, goal, proof: proof)
{:ok, certificate} = Theoria.Spec.check_claim(Theoria.new_env(), claim, goal, proof: proof)
```

If the structural claim is invalid, `Theoria.Spec.obligation/3` refuses to build the obligation and returns the claim kind and reason.

## Intended tool flow

```text
Elixir tool facts
  → structural spec claims
  → optional Theoria obligations
  → replayable certificates
  → CI / Vibe trust report
```

Reach, ex_ast, and Vibe should own domain-specific fact extraction. Theoria owns the generic claim vocabulary, kernel checking, certificate replay, and structured reports.
