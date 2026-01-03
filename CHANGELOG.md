# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
