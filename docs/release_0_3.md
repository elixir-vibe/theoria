# 0.3 development boundary

The 0.3 development line makes generated equation artifacts explicit domain data instead of public generated atoms.

## Equation identities

`Theoria.Equation.Name` is the canonical identity for generated equation artifacts:

```elixir
alias Theoria.Equation.Name

Name.equation(:nat_add, :succ)
Name.unfold(:nat_add)
Name.matcher_equation(:nat_add_match_1, :succ)
Name.indexed_matcher_equation(:vec_match, :vec_cons)
```

Friendly output still renders familiar labels such as `nat_add.eq_succ`, but those labels are display strings. When generated equation theorems are installed, the structured `Name` value itself is used as the environment key; generated atom encodings are not part of the model.

## Matcher names

Generated matcher declarations currently remain atoms such as `:nat_add_match_1`. Use `Theoria.Equation.Matcher.Info.default_name/2` and `source_name/1` instead of hand-building or parsing those names.

## Indexed Vec matcher opt-in

`Prelude.env/0` does not install indexed matchers or indexed matcher equations.

For validation and experiments, Vec exposes an explicit opt-in path:

```elixir
Theoria.Library.Vec.env_with_indexed_matcher()
Theoria.Library.Vec.env_with_indexed_matcher(install_equations: true)
```

The second form also installs realized indexed equation theorem declarations and records them in the matcher metadata. Rewrite and simp still exclude indexed matcher equations by default; pass `include_indexed_matchers: true` or use the indexed-specific database constructors when experimenting.

## Stability

This line is still experimental. The trusted kernel boundary is unchanged; equation generation, matcher planning, rewrite/simp, and Lean oracle output remain untrusted helpers whose products matter only after native kernel checking.
