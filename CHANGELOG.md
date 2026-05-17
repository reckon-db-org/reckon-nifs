# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Status: deprecated

**reckon-nifs 2.0.1 is the final release of this package.** As of
reckon-db 2.3.0 the six reckon-db NIFs are bundled directly into the
reckon-db hex package (`native/` + `priv/`), following the same
in-tree pattern macula has been using. New consumers should depend
only on `{reckon_db, "~> 2.3"}`.

The sidecar pattern caused three real bugs (silent name drift between
the Cargo package name and the `rustler::init!` target, a dead
central loader whose `persistent_term` keys nobody read, and a
cross-application `priv_dir` lookup that quietly fell back when the
consumer hadn't depended on reckon-nifs explicitly). All three
disappear when the NIFs live in the same package that uses them.

reckon-nifs stays on hex.pm so existing pinned consumers keep
working — reckon-db's wrapper modules retain a `code:priv_dir(reckon_nifs)`
fallback in their `-on_load(init/0)` for that reason. But this
package receives no further updates.

## [2.0.1] - 2026-05-17

### Fixed — Complete the `esdb_* → reckon_db_*` rename

v2.0.0 renamed the Rust crates but left three call-sites pointing
at the old names, which meant `rebar3 compile` from a fresh
checkout produced NO usable artefacts and the loader's
persistent_term keys were dead names that nothing read. Net effect:
consumers adding `reckon_nifs` as a dep saw their reckon-db
wrapper modules log "Community mode" anyway. Three things land
in 2.0.1:

- `rebar.config` pre_hooks + post_hooks: updated all seven cargo
  manifest paths and the `priv/` copy step to use the new
  `reckon_db_*` / `reckon_gater_*` crate names. The previous
  hooks pointed at `native/esdb_*/Cargo.toml` paths that no
  longer existed, and the file-copy step swallowed the failures
  with `|| true`, so the breakage was silent.
- `src/reckon_nifs_loader.erl`: removed the `esdb_*_loaded`
  persistent_term key writes entirely. Those keys were never
  read by anything — reckon-db's per-module `on_load` hooks set
  their own `reckon_db_*_nif_loaded` keys after a successful
  `erlang:load_nif/2` call. The loader has been recast as a
  presence-checker (`reckon_nifs_loader:verify/0`) that simply
  confirms the expected `.so` files are in `priv/` and reports
  any that are missing. `load_all/0` is kept as an alias so
  existing application start-up code keeps compiling.
- `priv/`: stale `esdb_*.so` binaries left over from before the
  v2.0.0 rename are removed; a fresh `rebar3 compile` will
  populate `priv/` with `reckon_db_*.so` and
  `reckon_gater_crypto_nif.so`.

### Why the loader doesn't call `erlang:load_nif/2`

`erlang:load_nif/2` only loads functions into the *calling module*
(via the `on_load` hook). A central loader cannot install NIF
stubs into another module's namespace. reckon-db's wrapper
modules each have their own `-on_load(init/0)` callback that
calls `erlang:load_nif/2` against `code:priv_dir(reckon_nifs)/
<their_own_name>`. So reckon-nifs's only job is to make sure the
`.so` files live at the expected path; the actual loading is
done by reckon-db.

The module docstring in `reckon_nifs_loader` documents this so
future readers don't restore the broken pattern.

### Other

- `src/reckon_nifs.app.src`: link changed from GitHub to Codeberg
  (Codeberg is the canonical forge for reckon-db-org).
- `README.md`: full pass to replace `esdb_*` references with the
  current crate names, update the example code to reflect the
  per-module `on_load` architecture, and bump the version
  alignment table to reckon-db 2.2.2 / reckon-gater 2.1.0.

## [2.0.0] - 2026-04-19

### Changed

**BREAKING**: All NIF crates renamed from `esdb_*` to layer-qualified
`reckon_{db,gater}_*` to match the overall reckon-db-org naming scheme.

| Old crate | New crate | Target layer |
|---|---|---|
| `esdb_aggregate_nif`    | `reckon_db_aggregate_nif`    | reckon-db |
| `esdb_archive_nif`      | `reckon_db_archive_nif`      | reckon-db |
| `esdb_crypto_nif`       | `reckon_db_crypto_nif`       | reckon-db |
| `esdb_filter_nif`       | `reckon_db_filter_nif`       | reckon-db |
| `esdb_graph_nif`        | `reckon_db_graph_nif`        | reckon-db |
| `esdb_hash_nif`         | `reckon_db_hash_nif`         | reckon-db |
| `esdb_gater_crypto_nif` | `reckon_gater_crypto_nif`    | reckon-gater |

Built `.so` / `.dylib` / `.dll` output names change accordingly. Consumers
(reckon-db and reckon-gater) update their `erlang:load_nif/2` target names
in their 2.0.0 releases.

### Migration

Rebuilds required. No API behaviour changes — function signatures and
return shapes are unchanged per crate.

## [1.0.0] - 2026-01-03

### Changed

- **Stable Release**: First stable release of reckon-nifs
- All APIs considered stable and ready for production use

## [0.1.0] - 2026-01-03

### Added
- Initial release as reckon-nifs (refactored from erl-esdb-nifs)
- Seven Rust NIF crates for high-performance operations:
  - `esdb_crypto_nif`: Ed25519 verify, SHA256, secure compare
  - `esdb_archive_nif`: LZ4/Zstd compression for archives
  - `esdb_hash_nif`: xxHash, FNV-1a for partitioning
  - `esdb_aggregate_nif`: Vectorized event aggregation
  - `esdb_filter_nif`: Regex/pattern matching
  - `esdb_graph_nif`: Graph algorithms (petgraph)
  - `esdb_gater_crypto_nif`: Base58, resource pattern matching
- Automatic NIF detection via persistent_term
- Apache-2.0 license

### Changed
- Package renamed from `erl_esdb_nifs` to `reckon_nifs`
- Organization changed from macula-io to reckon-db-org
- License changed from Commercial to Apache-2.0
