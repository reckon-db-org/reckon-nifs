# Contributing to reckon-nifs

reckon-nifs is the optional Rust acceleration package for [reckon-db](https://codeberg.org/reckon-db-org/reckon-db). Contributions are most valuable as: targeted performance improvements in the existing crates, support for additional platforms (Windows, FreeBSD, additional ARM variants), and bug reports backed by reproducible benchmarks.

## Reporting bugs

Open an issue on Codeberg: <https://codeberg.org/reckon-db-org/reckon-nifs/issues>.

Include:
- reckon-nifs version (`{vsn, ...}` from `src/reckon_nifs.app.src`, or the hex package version)
- reckon-db version (the consuming app's resolved version)
- Erlang/OTP version (`erl -version`)
- Rust toolchain version (`rustc --version`)
- Host architecture and OS (`uname -a`)
- Minimal reproduction — ideally an Erlang shell session showing which NIF wrapper module is failing and what error its `init/0` logged

For performance regressions, include benchmark numbers (before vs after) — otherwise it's hard to confirm a fix.

## Proposing a change

For non-trivial changes, open an issue first. The crate surface is intentionally small and we want to keep it that way.

### Pull request expectations

- **Touch only the layer that needs to change.** If a fix is in the Rust crate, change the crate; if it's in the loader/verifier, change the Erlang side. Don't conflate the two in one PR.
- **No new ex_doc warnings.** `rebar3 ex_doc` must complete clean.
- **No new dialyzer warnings.** `rebar3 dialyzer` must not add to the existing count.
- **No new cargo warnings.** `cargo build --release` should produce no warnings for any crate touched by the PR.
- **Tests where applicable.** The Erlang side has very few tests because the loader is largely declarative; add one for any new branch you introduce. The Rust side has rustler-friendly unit-test layouts — extend them when adding new NIF functions.
- **Bench when you claim a speedup.** Include before/after numbers in the PR description.

## Building locally

```bash
git clone https://codeberg.org/reckon-db-org/reckon-nifs.git
cd reckon-nifs
rebar3 compile         # runs cargo build --release for each crate + copies .so to priv/
rebar3 eunit           # runs Erlang unit tests
rebar3 ex_doc          # generates docs — must be warning-free
rebar3 dialyzer        # type-check
```

Per-crate Rust tests:

```bash
cd native/reckon_db_hash_nif
cargo test --release
```

## Code style

### Erlang
- 4-space indent, no tabs
- Inline documentation via edoc `@doc` tags (NOT markdown — edoc doesn't support backticks, `@see` URLs, or `@doc` on `-callback`/`-record`)
- Pure functions where possible — the loader/verifier should not have hidden side effects beyond what its name promises

### Rust
- `cargo fmt` before committing
- Avoid `unwrap()` in production paths — return `NifResult<T>` and let the Erlang side decide what to do with errors
- Document any `unsafe { ... }` block with a comment explaining why it is safe in context

## Releasing

Maintainer-only. The release procedure follows the workspace `~/.claude/CLAUDE.md` "Releasing a Package" checklist:

1. Pre-release verification: `rebar3 eunit`, `rebar3 dialyzer`, `rebar3 ex_doc`, all clean
2. Bump `{vsn, "X.Y.Z"}` in `src/reckon_nifs.app.src`
3. Update `CHANGELOG.md` with the version + date and a clear summary of changes
4. Commit (`chore: Release vX.Y.Z`)
5. Tag `vX.Y.Z`
6. Push commits + tags to Codeberg
7. `rebar3 hex publish` (maintainer-only, manual)

## Code of conduct

This project follows the [Contributor Covenant](CODE_OF_CONDUCT.md). By participating you agree to uphold its terms.

## License

Apache-2.0 — see [LICENSE](LICENSE). By submitting a pull request you agree your contribution is licensed under the same terms as the rest of the project.
