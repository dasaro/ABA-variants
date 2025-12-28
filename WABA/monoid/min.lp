%% Minimum Cost Monoid for Cost Aggregation - OPTIMIZED
%% Monoid: (ℤ ∪ {±∞}, min, #sup)
%% - Domain: All integers plus infinities
%% - Operation: minimum
%% - Identity: #sup (algebraic identity for min operation)
%%
%% Extension cost = minimum weight among all discarded attacks
%% This represents the "cheapest" attack that was discarded.
%% When no attacks are discarded, the cost is #sup (identity for min).
%%
%% OPTIMIZATION NOTES:
%% ===================
%% Removed redundant empty-case handling:
%% - REMOVED: discarded_attack(_,_,_) check in body
%% - REMOVED: extension_cost(#sup) :- not discarded_attack(_,_,_).
%% - Clingo naturally returns #min{} = #sup for empty sets (algebraic identity)
%% - Simplified from 2 rules to 1 rule
%%
%% DEFAULT WEIGHTS: Now defined in semiring files (moved from here)
%% - Semirings assign defaults using disjunction identity
%% - All weight assignment is now semiring responsibility
%% - Monoids only handle cost aggregation
%%
%% Note: MIN monoid uses LOWER BOUND regime (maximize quality threshold)
%% - LB constraint: :- extension_cost(C), C < B, budget(B).

%% Extension cost is the minimum discarded attack weight
%% OPTIMIZED: Rely on natural #min{} = #sup for empty sets
extension_cost(C) :- C = #min{ W, X, Y : discarded_attack(X,Y,W) }.

%% Budget constraint: Use constraint/lb.lp (Lower Bound regime)
%% Default beta=#inf is permissive (allows all extensions)
%% Override with -c beta=N to set minimum quality threshold
