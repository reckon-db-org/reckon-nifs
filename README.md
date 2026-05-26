# reckon-nifs
[![Buy Me A Coffee](https://img.shields.io/badge/Buy%20Me%20A%20Coffee-support-yellow.svg)](https://buymeacoffee.com/rlefever)

> **Status: deprecated as of 2026-05-17.** As of reckon-db 2.3.0, the
> six reckon-db NIFs are bundled directly with reckon-db itself (see
> `native/` and `priv/` in that repo). New consumers should depend
> only on `{reckon_db, "~> 2.3"}` — no separate reckon-nifs
> dependency is needed. **reckon-nifs 2.0.1 is the final release of
> this package.** It stays on hex.pm for existing pinned consumers,
> but receives no further updates.

**High-performance Rust NIF acceleration for reckon-db.**

This package ships compiled Rust implementations of reckon-db's hot-path operations. When `reckon_nifs` is on the code path, reckon-db's per-module `on_load` hooks pick up the `.so` files from `code:priv_dir(reckon_nifs)` and switch from the pure-Erlang fallbacks to the Rust fast path. No code changes required in consuming apps — adding the dep is enough.

Without reckon-nifs everything still works; reckon-db's wrapper modules log `"NIF not available (no_nif_found), using pure Erlang - Community mode"` at startup and use the Erlang implementations.

## Requirements

- **Rust toolchain** (cargo, rustc — stable) at the consumer's build host. Needed to compile the crates as part of `rebar3 compile`.

## Installation

```erlang
{deps, [
    {reckon_db, "~> 2.2"},
    {reckon_nifs, "~> 2.0"}  %% Optional: adds NIF acceleration
]}.
```

```bash
rebar3 compile
```

The rebar pre_hooks invoke `cargo build --release` for each crate; the post_hooks copy the resulting `.so` (or `.dylib` on macOS, packaged as `.so` for uniform load paths) into `priv/`.

## How it works

reckon-db's NIF wrapper modules (e.g. `reckon_db_hash_nif.erl`) declare:

```erlang
-on_load(init/0).

-define(NIF_LOADED_KEY, reckon_db_hash_nif_loaded).

init() ->
    NifName = "reckon_db_hash_nif",
    Paths = [
        case code:priv_dir(reckon_nifs) of
            {error, _} -> undefined;
            NifsDir    -> filename:join(NifsDir, NifName)
        end,
        case code:priv_dir(reckon_db) of
            {error, _} -> filename:join("priv", NifName);
            Dir        -> filename:join(Dir, NifName)
        end
    ],
    case try_load_nif([P || P <- Paths, P =/= undefined]) of
        ok ->
            persistent_term:put(?NIF_LOADED_KEY, true),
            logger:info("[reckon_db_hash_nif] NIF loaded - Enterprise mode"),
            ok;
        {error, Reason} ->
            persistent_term:put(?NIF_LOADED_KEY, false),
            logger:info("[reckon_db_hash_nif] NIF not available (~p), "
                        "using pure Erlang - Community mode", [Reason]),
            ok
    end.

xxhash64(Data) ->
    case persistent_term:get(?NIF_LOADED_KEY, false) of
        true  -> nif_xxhash64(Data);    %% Rust fast path
        false -> erlang_xxhash64(Data)  %% Pure Erlang fallback
    end.
```

`reckon_nifs_loader` itself does NOT call `erlang:load_nif/2` — that would not work, because NIFs can only be loaded into the module that owns the stub declarations. reckon_nifs's job is purely to provide the `.so` files in the right place, then let reckon-db's per-module `on_load` do the actual loading.

When `reckon_nifs` starts as an application it runs a presence check on `priv/` and logs which NIF binaries are missing, if any.

## Included NIFs

### Server-side (consumed by reckon-db)

| Module | Purpose | Speedup |
|--------|---------|---------|
| `reckon_db_crypto_nif` | Ed25519 verify, SHA256, secure compare | 3-5× |
| `reckon_db_archive_nif` | LZ4/Zstd compression for archives | 5-8× |
| `reckon_db_hash_nif` | xxHash, FNV-1a for partitioning | 10-15× |
| `reckon_db_aggregate_nif` | Vectorised event aggregation | 5-10× |
| `reckon_db_filter_nif` | Regex/pattern matching | 3-5× |
| `reckon_db_graph_nif` | Graph algorithms (petgraph) | 5-10× |

### Client-side (consumed by reckon-gater)

| Module | Purpose | Speedup |
|--------|---------|---------|
| `reckon_gater_crypto_nif` | Base58, resource pattern matching | 5-10× |

Speedup figures are workload-dependent and based on internal benchmarking; treat them as ballpark.

## Verifying acceleration is active

After starting the application stack, ask any of reckon-db's wrapper modules which mode they're in:

```erlang
1> application:ensure_all_started(reckon_nifs).
{ok, [reckon_nifs]}

2> reckon_db_hash_nif:implementation().
nif

3> persistent_term:get(reckon_db_hash_nif_loaded, false).
true
```

Or grep the startup logs for the reckon-db wrapper modules — each one logs either `NIF loaded - Enterprise mode` or `NIF not available (...) - Community mode` once during boot.

## Building from source

```bash
git clone https://codeberg.org/reckon-db-org/reckon-nifs.git
cd reckon-nifs
rebar3 compile
```

This runs `cargo build --release` for each of the seven crates and copies the artefacts to `priv/`.

## Troubleshooting

### Rust not found

```
error: cargo build failed
```

Install via [rustup.rs](https://rustup.rs/) or your distribution's package manager. The crates use the 2021 edition; any reasonably current stable toolchain works.

### NIF load failure on a consumer

The consumer's logs will show something like:

```
[reckon_db_hash_nif] NIF not available ({load_failed, "..."}), using pure Erlang - Community mode
```

Common causes:
- Missing Rust toolchain on the build host
- Architecture mismatch (built x86_64 image deployed on arm64 host, or vice versa)
- Missing system libraries (libc version skew between build and runtime base images)

### Verify priv/ contents

```bash
ls -la priv/
# Expected: reckon_db_*.so and reckon_gater_crypto_nif.so
```

If the file names still start with `esdb_*` you're looking at a stale build from before v2.0.1 — re-run `rebar3 clean && rebar3 compile`.

## Version alignment

| Package | Version | Source |
|---------|---------|--------|
| reckon-gater | 2.1.0 | hex.pm |
| reckon-db | 2.2.2 | hex.pm |
| reckon-nifs | 2.0.1 | hex.pm |

## License

Apache-2.0 — see [LICENSE](LICENSE).
