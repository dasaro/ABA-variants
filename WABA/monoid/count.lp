%% WABA Monoid: Count
%% Cost aggregation: Counts number of discarded attacks (weight-agnostic)
%%
%% Semantics:
%%   - extension_cost = number of discarded attack pairs
%%   - Ignores attack weights - only counts discards
%%   - Budget limits the COUNT of discards, not total weight cost
%%
%% Compatible semirings: All (weight-agnostic aggregation)
%%
%% Identity element: #sup (hardest to discard = infinite cost)
%% Budget constraint: C > B (enforce C <= B, standard cost limit)
%% Optimization: minimize extension_cost (prefer fewer discards)

%% Default weight for unweighted assumptions
%% (makes them hard to discard, compatible with all semirings)
supported_with_weight(X,#sup) :- assumption(X), in(X), not weight(X,_).

%% Count aggregation: number of discarded attacks
extension_cost(C) :- C = #count{ X,Y : discarded_attack(X,Y,_) }.

%% Identity: no discards = infinite cost (worst case)
extension_cost(#sup) :- not discarded_attack(_,_,_).

%% Budget violation (standard: cost exceeds budget)
budget_violation :- extension_cost(C), budget(B), C > B.
