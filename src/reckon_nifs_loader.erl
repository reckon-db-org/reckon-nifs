%% @doc NIF presence verifier for reckon-db.
%%
%% This module verifies that the reckon-nifs `priv/` directory
%% contains the expected compiled NIF shared objects, and exposes a
%% lookup function for consumers.
%%
%% == Important: this module does NOT call `erlang:load_nif/2` ==
%%
%% Each NIF wrapper module in reckon-db (e.g. `reckon_db_hash_nif',
%% `reckon_db_crypto_nif') self-loads its NIF via `-on_load(init/0)'.
%% That hook walks a search path that includes
%% `code:priv_dir(reckon_nifs)/<nif_name>'. As long as the .so file
%% is there under the right name, reckon-db picks it up and sets its
%% own `<nif_name>_loaded' persistent_term key.
%%
%% Calling `erlang:load_nif/2' from this module would not help —
%% NIFs can only be loaded into the module that owns the stub
%% declarations. So reckon_nifs's job is purely to provide the .so
%% files in the right place, then let reckon-db's per-module
%% `-on_load' do the loading.
%%
%% Prior to v2.0.1 this module actively tried to `erlang:load_nif'
%% from outside the target modules and set its own keys with the
%% legacy `esdb_*' prefix; both behaviours were no-ops at best and
%% the keys it set were never read. The module is now a verifier.
%%
%% @author rgfaber
-module(reckon_nifs_loader).

-export([load_all/0, verify/0, nif_path/1, available_nifs/0]).

%% Canonical list of NIF names this package ships. Each entry is
%% the *file basename* under priv/ (without the .so suffix). These
%% must match the `NifName' string in reckon-db's per-module init/0
%% so reckon-db's `code:priv_dir(reckon_nifs)/<NifName>' lookup
%% resolves.
-define(NIF_NAMES, [
    reckon_db_crypto_nif,
    reckon_db_archive_nif,
    reckon_db_hash_nif,
    reckon_db_aggregate_nif,
    reckon_db_filter_nif,
    reckon_db_graph_nif,
    reckon_gater_crypto_nif
]).

%% @doc Verify that all expected NIF .so files are present in priv/.
%%
%% Returns `ok' if every NIF in [[available_nifs/0]] has a
%% corresponding .so file in `priv/'; otherwise `{missing, [Name]}'
%% listing the absent ones. Does NOT call `erlang:load_nif/2' — see
%% the module-level docstring.
%%
%% This is the function the application's `start/2' callback calls.
%% The legacy name `load_all/0' is kept (now a synonym for
%% [[verify/0]]) so external `application:ensure_all_started/1' flows
%% from prior reckon-nifs 1.x / 2.0.0 keep compiling against this
%% release.
-spec load_all() -> ok | {missing, [atom()]}.
load_all() ->
    verify().

%% @doc Same as [[load_all/0]] — preferred name for new callers.
-spec verify() -> ok | {missing, [atom()]}.
verify() ->
    PrivDir = get_priv_dir(),
    Missing = [N || N <- ?NIF_NAMES, not filelib:is_regular(nif_path(PrivDir, N))],
    case Missing of
        []  -> ok;
        _   -> {missing, Missing}
    end.

%% @doc Resolve the on-disk path for a given NIF basename. Returns
%% the path even if the file doesn't exist — caller decides what to
%% do with that.
-spec nif_path(atom()) -> file:filename().
nif_path(NifName) ->
    nif_path(get_priv_dir(), NifName).

%% @doc List the NIF names this package ships.
-spec available_nifs() -> [atom()].
available_nifs() ->
    ?NIF_NAMES.

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
nif_path(PrivDir, NifName) ->
    filename:join(PrivDir, atom_to_list(NifName) ++ ".so").
