%% Semi-Stable Semantics
%% =====================
%%
%% Definition: Complete extensions S with maximal range(S)
%%            where range(S) = S ∪ {Y : ∃X∈S, att(X,Y)}
%%
%% Semantic: Complete extensions that maximize "reach"
%%
%% Inclusion: stable ⊆ semi-stable ⊆ preferred
%%
%% Usage:
%%   clingo -n 0 --opt-mode=optN WABA/core/base.lp WABA/semiring/godel.lp \
%%          WABA/monoid/max_minimization.lp WABA/filter/standard.lp \
%%          WABA/semantics/semistable.lp framework.lp
%%
%% Expected for test/aspforaba_journal_example.lp with beta=0: TBD

#include "complete.lp".

%% Define attack relation without weights for range computation
att(X,Y) :- attacks_successfully_with_weight(X,Y,_).

%% Range of extension S: S ∪ {Y : ∃X supported by S, att(X,Y)}
%% In ABA, range includes assumptions in S plus all assumptions attacked by elements supported by S
in_range(Y) :- in(Y).                      % Assumptions in extension
in_range(Y) :- supported(X), att(X,Y).    % Assumptions attacked by supported elements

%% Maximize range size as proxy for set inclusion
#maximize { 1@1,Y : in_range(Y) }.

#show in/1.
