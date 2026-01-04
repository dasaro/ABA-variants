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
%%   clingo -n 0 --heuristic=Domain --enum-mode=domRec \
%%          WABA/core/base.lp WABA/semiring/godel.lp \
%%          WABA/constraint/no_discard.lp WABA/filter/standard.lp \
%%          WABA/semantics/semistable.lp framework.lp
%%
%% Expected for test/aspforaba_journal_example.lp with no_discard: 2 extensions

#include "complete.lp".

%% Define attack relation without weights for range computation
att(X,Y) :- attacks_successfully_with_weight(X,Y,_).

%% Range of extension S: S ∪ {Y : ∃X supported by S, att(X,Y)}
%% In ABA, range includes assumptions in S plus all assumptions attacked by elements supported by S
in_range(Y) :- in(Y).                      % Assumptions in extension
in_range(Y) :- supported(X), att(X,Y).    % Assumptions attacked by supported elements

%% Prefer models with large range by preferring assumptions to be IN
%% (Heuristic approximation of range maximization)
miss(X) :- out(X), assumption(X).
#heuristic miss(X) : assumption(X). [1,false]

#show in/1.
