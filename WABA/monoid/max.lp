%% Maximum Cost Monoid for Cost Aggregation
%% Monoid: (ℤ ∪ {±∞}, max, #inf)
%% - Domain: All integers plus infinities
%% - Operation: maximum
%% - Identity: #inf (algebraic identity for max operation)
%% - Null value: 0 (when no attacks discarded, cost = 0 by design choice)
%%
%% Extension cost = maximum weight among all discarded attacks
%% This represents the "most expensive" attack that was discarded.
%% When no attacks are discarded, we use 0 (not the identity #inf) to represent "no cost".
%%
%% UNWEIGHTED ATOMS: Default weight = #sup (infinity)
%% Rationale: With max monoid, hardest-to-discard = largest weight
%% - extension_cost = max(#sup, ...) = #sup → infinitely expensive
%% - Can only discard if budget = #sup (unbounded)
%% - Compatible semirings: fuzzy, probabilistic (min has identity #sup)
%%
supported_with_weight(X,#sup) :-
    assumption(X), in(X), not weight(X,_).

%% Extension cost is the maximum discarded attack weight
%% Only compute aggregate when discarded attacks exist
extension_cost(C) :- discarded_attack(_,_,_), C = #max{ W, X, Y : discarded_attack(X,Y,W) }.

%% When no attacks are discarded, cost is 0 (identity element)
extension_cost(0) :- not discarded_attack(_,_,_).

%% Budget constraint: Use constraint/ub.lp (Upper Bound regime)
