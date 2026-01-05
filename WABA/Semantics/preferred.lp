%% Preferred Semantics
%% Maximal complete extensions (w.r.t. set inclusion)
%%
%% Implementation: Maximize |in| with range tie-breaker
%% Priority @5 for cardinality (main), @4 for range (tie-breaker)

#include "complete.lp".

%% Define attack relation without weights for range computation
att(X,Y) :- attacks_successfully_with_weight(X,Y,_).

%% Range of extension S: S ∪ {Y : ∃X supported by S, att(X,Y)}
in_range(Y) :- in(Y).                      % Assumptions in extension
in_range(Y) :- supported(X), att(X,Y).    % Assumptions attacked by supported elements

%% MAIN (@5): Maximize cardinality of extension as proxy for set inclusion maximality
%% TIE-BREAKER (@4): Maximize range to refine among equal-size extensions
%% Priority @5 > @4 ensures clean separation
#maximize { 1@5, X : in(X); 1@4, Y : in_range(Y) }.
