# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
