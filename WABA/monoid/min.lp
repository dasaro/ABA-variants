%% Minimum Cost Monoid for Cost Aggregation
%% Monoid: (ℤ ∪ {±∞}, min, #sup)
%% - Domain: All integers plus infinities
%% - Operation: minimum
%% - Identity: #sup (algebraic identity for min operation)
%%
%% Extension cost = minimum weight among all discarded attacks
%% This represents the "cheapest" attack that was discarded.
%% When no attacks are discarded, the cost is #sup (identity for min).
%%
%% UNWEIGHTED ATOMS: Default weight = 0
%% Rationale: With min monoid, hardest-to-discard = smallest weight
%% - To minimize extension_cost = min(discarded), prefer discarding LARGER weights
%% - Smallest weight (0) is hardest to discard (forces min=0)
%% - Compatible semirings: tropical (+ operation has identity 0)
%% - INCOMPATIBLE: fuzzy/probabilistic (min operation has identity #sup, conflicts!)
%%
supported_with_weight(X,0) :-
    assumption(X), in(X), not weight(X,_).

%% Extension cost is the minimum discarded attack weight
%% Only compute aggregate when discarded attacks exist
extension_cost(C) :- discarded_attack(_,_,_), C = #min{ W, X, Y : discarded_attack(X,Y,W) }.

%% When no attacks are discarded, cost is #sup (identity for min operation)
extension_cost(#sup) :- not discarded_attack(_,_,_).

%% Budget constraint: Use constraint/lb.lp (Lower Bound regime)
%% Default beta=#inf is permissive (allows all extensions)
%% Override with -c beta=N to set minimum quality threshold
