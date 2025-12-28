%% Sum Monoid for Cost Aggregation - OPTIMIZED
%% Monoid: (ℤ ∪ {±∞}, +, 0)
%% - Domain: All integers plus infinities
%% - Operation: sum (addition)
%% - Identity: 0 (algebraic identity for addition)
%%
%% Extension cost = sum of all discarded attack weights
%% This represents the "total cost" of all discarded attacks.
%%
%% OPTIMIZATION NOTES:
%% ===================
%% Removed redundant empty-case handling:
%% - REMOVED: discarded_attack(_,_,_) check in body
%% - REMOVED: extension_cost(0) :- not discarded_attack(_,_,_).
%% - Clingo naturally returns #sum{} = 0 for empty sets (algebraic identity)
%% - Simplified from 2 rules to 1 rule
%%
%% Note: With multiple derivations of the same attack via different rules,
%% each derivation contributes its weight to the sum.
%% The tuple (W, X, Y) ensures each unique attack instance is counted.
%%
%% DEFAULT WEIGHTS: Now defined in semiring files (moved from here)
%% - Semirings assign defaults using disjunction identity
%% - All weight assignment is now semiring responsibility
%% - Monoids only handle cost aggregation

%% Extension cost is the sum of all discarded attack weights
%% OPTIMIZED: Rely on natural #sum{} = 0 for empty sets
extension_cost(C) :- C = #sum{ W, X, Y : discarded_attack(X,Y,W) }.

%% Budget constraint: Use constraint/ub.lp (Upper Bound regime)
