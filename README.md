# reckon-nifs
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow.svg)](https://buymeacoffee.com/beamologist)

**High-performance NIF acceleration package for reckon-db.**

This package provides Rust-based high-performance implementations for reckon-db operations. When installed, reckon-db automatically detects and uses these NIFs for 5-10x performance improvement.

## Requirements

- **Rust toolchain**: cargo, rustc (stable)

## Installation

Add to your `rebar.config` alongside reckon-db:

```erlang
{deps, [
    {reckon_db, "1.0.0"},
    {reckon_nifs, "1.0.0"}  %% Optional: adds NIF acceleration
]}.
```

**Note:** reckon-nifs has NO dependencies. It provides NIFs that reckon-db and reckon-gater can optionally use for acceleration.

Then compile:

```bash
rebar3 compile
```

The NIFs are automatically detected and used. No code changes required.

## How It Works

reckon-db modules check for NIF availability at runtime via persistent_term:

```erlang
%% In esdb_hash_nif.erl (part of reckon-db)
xxhash64(Data) ->
    case persistent_term:get(esdb_hash_nif_loaded, false) of
        true -> nif_xxhash64(Data);      %% NIF accelerated
        false -> erlang_xxhash64(Data)   %% Pure Erlang fallback
    end.
```

When reckon_nifs starts, it loads the Rust NIFs and sets the persistent_term keys, enabling the fast path.

## Included NIFs

### Server-side (from reckon-db)

| Module | Purpose | Speedup |
|--------|---------|---------|
| `esdb_crypto_nif` | Ed25519 verify, SHA256, secure compare | 3-5x |
| `esdb_archive_nif` | LZ4/Zstd compression for archives | 5-8x |
| `esdb_hash_nif` | xxHash, FNV-1a for partitioning | 10-15x |
| `esdb_aggregate_nif` | Vectorized event aggregation | 5-10x |
| `esdb_filter_nif` | Regex/pattern matching | 3-5x |
| `esdb_graph_nif` | Graph algorithms (petgraph) | 5-10x |

### Client-side (from reckon-gater)

| Module | Purpose | Speedup |
|--------|---------|---------|
| `esdb_gater_crypto_nif` | Base58, resource pattern matching | 5-10x |

## Verification

Check if NIFs are loaded:

```erlang
1> application:ensure_all_started(reckon_nifs).
{ok, [reckon_nifs]}

2> esdb_hash_nif:implementation().
nif  %% NIF accelerated mode

3> persistent_term:get(esdb_hash_nif_loaded, false).
true
```

Without reckon_nifs:

```erlang
1> esdb_hash_nif:implementation().
erlang  %% Pure Erlang mode
```

## Building from Source

```bash
git clone https://codeberg.org/reckon-db-org/reckon-nifs.git
cd reckon-nifs
rebar3 compile
```

This compiles all Rust crates and copies the `.so` files to `priv/`.

## Troubleshooting

### Rust not found

```
error: cargo build failed
```

Install Rust: https://rustup.rs/

### NIF load failure

Check the Erlang shell for warnings:

```
[warning] Failed to load esdb_hash_nif: {load_failed, "..."}
```

Common causes:
- Missing Rust toolchain
- Architecture mismatch (x86 vs ARM)
- Missing system libraries (libc, etc.)

### Verify priv/ contents

```bash
ls -la priv/
# Should show: esdb_*.so files
```

## License

Apache-2.0 - See [LICENSE](LICENSE)

## Version Alignment

| Package | Version | Source |
|---------|---------|--------|
| reckon-gater | 0.1.0 | hex.pm |
| reckon-db | 0.1.0 | hex.pm |
| reckon-nifs | 0.1.0 | hex.pm |
