# 0.7 release checklist

Use this checklist before preparing or publishing 0.7.0. Publishing and tagging are external release side effects and require explicit approval plus Hex 2FA.

## Validation

Run:

```bash
mix ci
mix docs
mix theoria.lean.check
mix hex.build
mix run examples/kernel_reports/run.exs
mix run examples/simp_capabilities/run.exs
mix run examples/proof_simp_trace/run.exs
rm -f theoria-*.tar
```

Expected high-level checks:

- native validation passes;
- Lean oracle passes when Lean is available;
- docs build without warnings;
- Hex package builds;
- generated tarballs are removed;
- downstream smoke test passes as part of `mix ci`;
- package file tests exclude `fixtures`, `test`, `_build`, and generated `doc` output.

## Changelog and version

Before release preparation:

- convert `## Unreleased` to `## 0.7.0`;
- do not add release date lines;
- keep notes user-facing and concise;
- confirm `mix.exs` version is `0.7.0` in the release commit.

## Release side effects

Do not run these without explicit approval:

```bash
git tag v0.7.0
mix hex.publish
gh release create v0.7.0
```

Hex publish requires an interactive 2FA code.
