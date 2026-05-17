-module(reckon_nifs_loader_tests).

-include_lib("eunit/include/eunit.hrl").

%%====================================================================
%% Module shape
%%====================================================================

module_exports_test() ->
    Exports = reckon_nifs_loader:module_info(exports),
    ?assert(lists:member({verify, 0}, Exports)),
    ?assert(lists:member({load_all, 0}, Exports)),
    ?assert(lists:member({available_nifs, 0}, Exports)),
    ?assert(lists:member({nif_path, 1}, Exports)).

%%====================================================================
%% available_nifs/0 contract
%%====================================================================

%% The list must include every NIF reckon-db (and reckon-gater) will
%% try to load via `code:priv_dir(reckon_nifs)/<name>`. If this list
%% drifts away from what consumers expect, those consumers silently
%% fall back to Erlang implementations — exactly the bug 2.0.1 fixed.
available_nifs_includes_all_expected_test() ->
    Names = reckon_nifs_loader:available_nifs(),
    Expected = [
        reckon_db_crypto_nif,
        reckon_db_archive_nif,
        reckon_db_hash_nif,
        reckon_db_aggregate_nif,
        reckon_db_filter_nif,
        reckon_db_graph_nif,
        reckon_gater_crypto_nif
    ],
    [?assert(lists:member(N, Names)) || N <- Expected].

available_nifs_uses_new_naming_test_() ->
    Names = reckon_nifs_loader:available_nifs(),
    [{"no legacy `esdb_*` names leak through (regression for 2.0.1)",
      ?_assertEqual([], [N || N <- Names,
                              lists:prefix("esdb_", atom_to_list(N))])}].

%%====================================================================
%% nif_path/1 contract
%%====================================================================

nif_path_appends_so_suffix_test() ->
    Path = reckon_nifs_loader:nif_path(reckon_db_hash_nif),
    ?assertEqual(".so", filename:extension(Path)),
    ?assertEqual("reckon_db_hash_nif.so", filename:basename(Path)).

%%====================================================================
%% verify/0 behaviour
%%====================================================================

%% In the dev tree, `rebar3 compile' has already populated `priv/'
%% with the seven .so files. So `verify/0' should report `ok'.
%% This is also a smoke-test of the cargo build pipeline — if
%% any of the seven crates failed to produce a .so, this test will
%% surface it as a `{missing, [...]}` return.
verify_in_dev_tree_test() ->
    case reckon_nifs_loader:verify() of
        ok ->
            ?assert(true);
        {missing, Names} ->
            ?assertEqual([], Names,
                "Expected an empty missing-list; cargo build "
                "must have produced every .so")
    end.

load_all_is_synonym_for_verify_test() ->
    ?assertEqual(reckon_nifs_loader:verify(),
                 reckon_nifs_loader:load_all()).
