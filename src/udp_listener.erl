%%%----------------------------------------------------------------------
%%%
%%% This program is free software; you can redistribute it and/or
%%% modify it under the terms of the GNU General Public License as
%%% published by the Free Software Foundation; either version 3 of the
%%% License, or (at your option) any later version.
%%%
%%% This program is distributed in the hope that it will be useful,
%%% but WITHOUT ANY WARRANTY; without even the implied warranty of
%%% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
%%% General Public License for more details.
%%%
%%% You should have received a copy of the GNU General Public License
%%% along with this program; if not, write to the Free Software
%%% Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
%%% 02111-1307 USA
%%%
%%%----------------------------------------------------------------------

-module(udp_listener).
-author('lemenkov@gmail.com').

-define(PARENT, stund).

-behaviour(gen_server).
-export([start_link/1]).
-export([init/1]).
-export([handle_call/3]).
-export([handle_cast/2]).
-export([handle_info/2]).
-export([code_change/3]).
-export([terminate/2]).

start_link(Args) ->
	gen_server:start_link({local, udp_listener}, ?MODULE, Args, []).

init ([{I0, I1, I2, I3, I4, I5, I6, I7} = IPv6, Port]) when
	is_integer(I0), I0 >= 0, I0 < 65535,
	is_integer(I1), I1 >= 0, I1 < 65535,
	is_integer(I2), I2 >= 0, I2 < 65535,
	is_integer(I3), I3 >= 0, I3 < 65535,
	is_integer(I4), I4 >= 0, I4 < 65535,
	is_integer(I5), I5 >= 0, I5 < 65535,
	is_integer(I6), I6 >= 0, I6 < 65535,
	is_integer(I7), I7 >= 0, I7 < 65535 ->
	{ok, Fd} = gen_udp:open(Port, [{ip, IPv6}, {active, true}, binary, inet6]),
	error_logger:info_msg("UDP listener started at [~s:~w]~n", [inet_parse:ntoa(IPv6), Port]),
	{ok, Fd};
init ([{I0, I1, I2, I3} = IPv4, Port]) when
	is_integer(I0), I0 >= 0, I0 < 256,
	is_integer(I1), I1 >= 0, I1 < 256,
	is_integer(I2), I2 >= 0, I2 < 256,
	is_integer(I3), I3 >= 0, I3 < 256 ->
	{ok, Fd} = gen_udp:open(Port, [{ip, IPv4}, {active, true}, binary]),
	error_logger:info_msg("UDP listener started at [~s:~w]~n", [inet_parse:ntoa(IPv4), Port]),
	{ok, Fd}.

handle_call(Other, _From, State) ->
	error_logger:warning_msg("UDP listener: strange call: ~p~n", [Other]),
	{noreply, State}.

handle_cast({Msg, Ip, Port}, Fd) ->
	gen_udp:send(Fd, Ip, Port, Msg),
	{noreply, Fd};

handle_cast(stop, State) ->
	{stop, normal, State};

handle_cast(Other, State) ->
	error_logger:warning_msg("UDP listener: strange cast: ~p~n", [Other]),
	{noreply, State}.

% Fd from which message arrived must be equal to Fd from our state
handle_info({udp, Fd, FIp, FPort, Msg}, Fd) ->
	{ok, {TIp, TPort}} = inet:sockname(Fd),
	gen_server:cast(?PARENT, {udp_listener, Msg, FIp, FPort, TIp, TPort}),
	{noreply, Fd};

handle_info(Info, State) ->
	error_logger:warning_msg("UDP listener: strange info: ~p~n", [Info]),
	{noreply, State}.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

terminate(Reason, Fd) ->
	gen_udp:close(Fd),
	error_logger:error_msg("UDP listener closed: ~p~n", [Reason]),
	ok.
