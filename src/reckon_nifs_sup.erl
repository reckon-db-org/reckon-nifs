%% @doc reckon-nifs Top Supervisor
%%
%% Minimal supervisor for the reckon_nifs application.
%% Currently has no children - NIFs are stateless and loaded at startup.
%%
%% @author rgfaber
-module(reckon_nifs_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

-spec start_link() -> {ok, pid()} | {error, term()}.
start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

-spec init([]) -> {ok, {supervisor:sup_flags(), [supervisor:child_spec()]}}.
init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 1,
        period => 5
    },
    ChildSpecs = [],
    {ok, {SupFlags, ChildSpecs}}.
