# 0.8 release checklist

0.8 stabilizes public theorem DSL and equation API workflows while keeping matcher/indexed internals experimental.

## API/docs checks

- Public APIs are documented primarily in module docs.
- `docs/public_api.md` accurately separates stable-ish, experimental, and contributor APIs.
- `docs/equations.md` documents structured identities, the `Theoria.Equation` facade, and `mix theoria.equations` JSON output.
- `docs/theorem_modules.md` covers independent theorem checking, `--install`, and common failures.
- README links stay user-facing and avoid internal release/checklist noise.

## Validation commands

Run before release preparation:

```bash
mix format --check-formatted
mix ci
mix docs
mix theoria.lean.check
mix hex.build
mix run examples/generated_equations/run.exs
mix run examples/simp_realization/run.exs
mix run examples/kernel_reports/run.exs
mix run examples/simp_capabilities/run.exs
mix run examples/proof_simp_trace/run.exs
mix run examples/theorem_module/run.exs
rm -f theoria-*.tar
```

## Release side-effect order

1. Prepare the release commit and changelog.
2. Build and inspect the Hex package.
3. Publish to Hex only with a fresh 2FA code from the user.
4. Create the Git tag and GitHub release only after Hex publish succeeds.
5. Remove generated `theoria-*.tar` files.

Do not rewrite published releases.
