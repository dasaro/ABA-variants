%% WABA Monoid: Count
%% Cost aggregation: Counts number of discarded attacks (weight-agnostic)
%%
%% Monoid: (ℕ ∪ {∞}, count, 0)
%% - Domain: Natural numbers plus infinity
%% - Operation: count (cardinality)
%% - Identity: 0 (algebraic identity: count of empty set = 0)
%% - Null value: #sup (when no attacks discarded, for optimization direction)
%%
%% Semantics:
%%   - extension_cost = number of discarded attack pairs
%%   - Ignores attack weights - only counts discards
%%   - Budget limits the COUNT of discards, not total weight cost
%%
%% Compatible semirings: All (weight-agnostic aggregation)
%% Budget constraint: C > B (enforce C <= B, standard cost limit)
%% Optimization: minimize extension_cost (prefer fewer discards)

%% Default weight for unweighted assumptions
%% (makes them hard to discard, compatible with all semirings)
supported_with_weight(X,#sup) :- assumption(X), in(X), not weight(X,_).

%% Count aggregation: number of discarded attacks
extension_cost(C) :- C = #count{ X,Y : discarded_attack(X,Y,_) }.

%% Identity: no discards = infinite cost (worst case)
extension_cost(#sup) :- not discarded_attack(_,_,_).

%% Budget constraint: Use constraint/ub.lp (Upper Bound regime)
