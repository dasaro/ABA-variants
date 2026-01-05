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
%% Implementation: Maximize range size
%% Priority @5 for range maximization (no tie-breaker)

#include "complete.lp".

%% Define attack relation without weights for range computation
att(X,Y) :- attacks_successfully_with_weight(X,Y,_).

%% Range of extension S: S ∪ {Y : ∃X supported by S, att(X,Y)}
in_range(Y) :- in(Y).                      % Assumptions in extension
in_range(Y) :- supported(X), att(X,Y).    % Assumptions attacked by supported elements

%% MAIN (@5): Maximize range size to find ALL maximal-range extensions
%% No tie-breaker ensures all extensions with maximal range are returned
#maximize { 1@5, Y : in_range(Y) }.
