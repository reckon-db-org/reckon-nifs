%% @doc reckon-nifs Application Module
%%
%% This application provides Rust NIF implementations for reckon-db.
%% When started, it loads all available NIFs and registers them
%% via persistent_term so that reckon-db can detect and use them.
%%
%% == Usage ==
%%
%% Add reckon_nifs as a dependency in your rebar.config:
%%
%% ```
%% {deps, [
%%     {reckon_db, "0.1.0"},
%%     {reckon_nifs, "0.1.0"}  %% Optional: adds NIF acceleration
%% ]}.
%% '''
%%
%% reckon_nifs has NO dependencies on reckon-db. The dependency flows the
%% other way: reckon-db optionally detects and uses reckon_nifs for acceleration.
%%
%% @author Reckon-DB
-module(reckon_nifs_app).
-behaviour(application).

-export([start/2, stop/1]).

%% @doc Start the application and load all NIFs.
-spec start(application:start_type(), term()) -> {ok, pid()} | {error, term()}.
start(_StartType, _StartArgs) ->
    case reckon_nifs_loader:load_all() of
        ok ->
            logger:info("[reckon_nifs] All NIFs loaded successfully - Enterprise mode enabled"),
            reckon_nifs_sup:start_link();
        {error, Reason} ->
            logger:error("[reckon_nifs] Failed to load NIFs: ~p", [Reason]),
            {error, Reason}
    end.

%% @doc Stop the application.
-spec stop(term()) -> ok.
stop(_State) ->
    ok.
