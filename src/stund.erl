%%%----------------------------------------------------------------------
%%% Copyright (c) 2012 Peter Lemenkov <lemenkov@gmail.com>
%%%
%%% All rights reserved.
%%%
%%% Redistribution and use in source and binary forms, with or without modification,
%%% are permitted provided that the following conditions are met:
%%%
%%% * Redistributions of source code must retain the above copyright notice, this
%%% list of conditions and the following disclaimer.
%%% * Redistributions in binary form must reproduce the above copyright notice,
%%% this list of conditions and the following disclaimer in the documentation
%%% and/or other materials provided with the distribution.
%%% * Neither the name of the authors nor the names of its contributors
%%% may be used to endorse or promote products derived from this software
%%% without specific prior written permission.
%%%
%%% THIS SOFTWARE IS PROVIDED BY THE REGENTS AND CONTRIBUTORS ''AS IS'' AND ANY
%%% EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
%%% WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
%%% DISCLAIMED. IN NO EVENT SHALL THE REGENTS OR CONTRIBUTORS BE LIABLE FOR ANY
%%% DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
%%% (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
%%% LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
%%% ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
%%% (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
%%% SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
%%%
%%%----------------------------------------------------------------------

-module(stund).
-behaviour(gen_server).

%% ------------------------------------------------------------------
%% API Function Exports
%% ------------------------------------------------------------------

-export([start_link/0]).

%% ------------------------------------------------------------------
%% gen_server Function Exports
%% ------------------------------------------------------------------

-export([init/1, handle_call/3, handle_cast/2, handle_info/2,
		terminate/2, code_change/3]).

%% ------------------------------------------------------------------
%% External Definitions
%% ------------------------------------------------------------------

-include_lib("rtplib/include/stun.hrl").

%% ------------------------------------------------------------------
%% API Function Definitions
%% ------------------------------------------------------------------

start_link() ->
	gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

%% ------------------------------------------------------------------
%% gen_server Function Definitions
%% ------------------------------------------------------------------

-record(state, {
	}).

init(Args) ->
	{ok, Args}.

handle_call(_Request, _From, State) ->
	{reply, ok, State}.

handle_cast({Listener, Msg, FIp, FPort, TIp, TPort}, State) ->
	{ok, Stun} = stun:decode(Msg),
	TID = Stun#stun.transactionid,
	StunResp = #stun{
		class = success,
		method = binding,
		transactionid = TID,
		fingerprint = false,
		attrs = [
			{'MAPPED-ADDRESS',{FIp,FPort}},
			{'SOURCE-ADDRESS',{TIp,TPort}},
			{'SOFTWARE',<<"ErlSTUNd (based on rtplib)">>}
		]
	},
	gen_server:cast(Listener, {stun:encode(StunResp), FIp, FPort}),
	{noreply, State};

handle_cast(_Msg, State) ->
	{noreply, State}.

handle_info(_Info, State) ->
	{noreply, State}.

terminate(_Reason, _State) ->
	ok.

code_change(_OldVsn, State, _Extra) ->
	{ok, State}.

%% ------------------------------------------------------------------
%% Internal Function Definitions
%% ------------------------------------------------------------------
