%% @doc NIF Loader for reckon-db
%%
%% This module loads all Rust NIFs and registers their availability
%% via persistent_term. The reckon-db NIF wrapper modules check these
%% persistent_term keys to determine whether to use the NIF or fall
%% back to pure Erlang implementations.
%%
%% == How Detection Works ==
%%
%% Each NIF module in reckon-db has a pattern like:
%%
%% ```
%% -define(NIF_LOADED_KEY, esdb_hash_nif_loaded).
%%
%% is_nif_loaded() ->
%%     persistent_term:get(?NIF_LOADED_KEY, false).
%%
%% xxhash64(Data) ->
%%     case is_nif_loaded() of
%%         true -> nif_xxhash64(Data);      %% Fast path (NIF)
%%         false -> erlang_xxhash64(Data)   %% Fallback (Erlang)
%%     end.
%% '''
%%
%% When this loader runs, it sets the persistent_term keys to `true`,
%% causing reckon-db to use the NIF implementations.
%%
%% @author Reckon-DB
-module(reckon_nifs_loader).

-export([load_all/0, load_nif/2, is_loaded/1]).

%% NIF name to persistent_term key mapping
%% Server-side NIFs (used by reckon-db):
%%   esdb_crypto_nif - Ed25519, SHA256, secure compare
%%   esdb_archive_nif - LZ4 compression
%%   esdb_hash_nif - xxHash, FNV-1a
%%   esdb_aggregate_nif - Event aggregation
%%   esdb_filter_nif - Regex/pattern matching
%%   esdb_graph_nif - Graph algorithms
%% Client-side NIFs (used by reckon-gater):
%%   esdb_gater_crypto_nif - Base58, resource pattern matching
-define(NIF_KEYS, [
    {esdb_crypto_nif, esdb_crypto_nif_loaded},
    {esdb_archive_nif, esdb_archive_nif_loaded},
    {esdb_hash_nif, esdb_hash_nif_loaded},
    {esdb_aggregate_nif, esdb_aggregate_nif_loaded},
    {esdb_filter_nif, esdb_filter_nif_loaded},
    {esdb_graph_nif, esdb_graph_nif_loaded},
    {esdb_gater_crypto_nif, esdb_gater_crypto_nif_loaded}
]).

%% @doc Load all available NIFs.
%% Returns ok if all NIFs loaded successfully, or {error, Failures} if any failed.
-spec load_all() -> ok | {error, [{atom(), term()}]}.
load_all() ->
    PrivDir = get_priv_dir(),
    Results = [load_nif_internal(PrivDir, NifName, Key) || {NifName, Key} <- ?NIF_KEYS],
    Failures = [{Name, Reason} || {Name, {error, Reason}} <- Results],
    case Failures of
        [] -> ok;
        _ -> {error, Failures}
    end.

%% @doc Load a specific NIF by name.
-spec load_nif(atom(), atom()) -> ok | {error, term()}.
load_nif(NifName, PersistentTermKey) ->
    PrivDir = get_priv_dir(),
    case load_nif_internal(PrivDir, NifName, PersistentTermKey) of
        {NifName, ok} -> ok;
        {NifName, {error, Reason}} -> {error, Reason}
    end.

%% @doc Check if a specific NIF is loaded.
-spec is_loaded(atom()) -> boolean().
is_loaded(PersistentTermKey) ->
    persistent_term:get(PersistentTermKey, false).

%%====================================================================
%% Internal Functions
%%====================================================================

%% @private
get_priv_dir() ->
    case code:priv_dir(reckon_nifs) of
        {error, _} ->
            %% Fallback for development
            case code:which(?MODULE) of
                Filename when is_list(Filename) ->
                    filename:join(filename:dirname(filename:dirname(Filename)), "priv");
                _ ->
                    "priv"
            end;
        Dir ->
            Dir
    end.

%% @private
load_nif_internal(PrivDir, NifName, PersistentTermKey) ->
    Path = filename:join(PrivDir, atom_to_list(NifName)),
    case erlang:load_nif(Path, 0) of
        ok ->
            persistent_term:put(PersistentTermKey, true),
            logger:debug("[reckon_nifs] Loaded ~p", [NifName]),
            {NifName, ok};
        {error, {reload, _}} ->
            %% Already loaded
            persistent_term:put(PersistentTermKey, true),
            {NifName, ok};
        {error, Reason} ->
            logger:warning("[reckon_nifs] Failed to load ~p: ~p", [NifName, Reason]),
            {NifName, {error, Reason}}
    end.
