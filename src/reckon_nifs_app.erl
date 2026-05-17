%% @doc reckon-nifs Application Module
%%
%% Optional acceleration package for reckon-db. When this app is
%% started, reckon-db's per-module on_load hooks find the compiled
%% NIF .so files in `code:priv_dir(reckon_nifs)' and switch their
%% wrapper modules from the pure-Erlang fallbacks to the Rust fast
%% path.
%%
%% This module's start/2 callback is a presence-check only — it
%% does NOT itself call `erlang:load_nif/2'. See
%% [[reckon_nifs_loader]] for why.
%%
%% == Usage ==
%%
%% ```
%% {deps, [
%%     {reckon_db, "~> 2.2"},
%%     {reckon_nifs, "~> 2.0"}  %% Optional: adds NIF acceleration
%% ]}.
%% '''
%%
%% reckon_nifs has NO dependency on reckon-db. The dependency
%% flows the other way: reckon-db optionally looks for reckon_nifs's
%% priv/ for NIF binaries.
%%
%% @author rgfaber
-module(reckon_nifs_app).
-behaviour(application).

-export([start/2, stop/1]).

%% @doc Start the application and verify NIF binaries are present.
-spec start(application:start_type(), term()) ->
    {ok, pid()} | {error, term()}.
start(_StartType, _StartArgs) ->
    case reckon_nifs_loader:verify() of
        ok ->
            logger:info("[reckon_nifs] All ~p NIF binaries present in priv/ — "
                        "reckon-db's per-module on_load hooks will pick them up",
                        [length(reckon_nifs_loader:available_nifs())]),
            reckon_nifs_sup:start_link();
        {missing, Names} ->
            %% Not strictly fatal — reckon-db will simply log
            %% "Community mode" for the missing ones and use Erlang
            %% fallbacks. But the user added reckon_nifs as a dep
            %% expecting acceleration, so warn so the operator can
            %% investigate why `cargo build --release' didn't produce
            %% every artefact.
            logger:warning("[reckon_nifs] Missing NIF binaries in priv/: ~p. "
                           "Did the cargo build step succeed for every crate?",
                           [Names]),
            reckon_nifs_sup:start_link()
    end.

%% @doc Stop the application.
-spec stop(term()) -> ok.
stop(_State) ->
    ok.
