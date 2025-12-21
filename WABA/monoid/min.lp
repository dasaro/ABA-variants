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
%% DEFAULT WEIGHTS: Now defined in semiring files (moved from here)
%% - Semirings assign defaults using disjunction identity
%% - All weight assignment is now semiring responsibility
%% - Monoids only handle cost aggregation
%%
%% Note: MIN monoid uses LOWER BOUND regime (maximize quality threshold)
%% - LB constraint: :- extension_cost(C), C < B, budget(B).

%% Extension cost is the minimum discarded attack weight
%% Only compute aggregate when discarded attacks exist
extension_cost(C) :- discarded_attack(_,_,_), C = #min{ W, X, Y : discarded_attack(X,Y,W) }.

%% When no attacks are discarded, cost is #sup (identity for min operation)
extension_cost(#sup) :- not discarded_attack(_,_,_).

%% Budget constraint: Use constraint/lb.lp (Lower Bound regime)
%% Default beta=#inf is permissive (allows all extensions)
%% Override with -c beta=N to set minimum quality threshold
