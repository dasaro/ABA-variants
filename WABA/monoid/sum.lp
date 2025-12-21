%% Sum Monoid for Cost Aggregation
%% Monoid: (ℤ ∪ {±∞}, +, 0)
%% - Domain: All integers plus infinities
%% - Operation: sum (addition)
%% - Identity: 0 (algebraic identity for addition)
%%
%% Extension cost = sum of all discarded attack weights
%% This represents the "total cost" of all discarded attacks.
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
%% Only compute aggregate when discarded attacks exist
extension_cost(C) :- discarded_attack(_,_,_), C = #sum{ W, X, Y : discarded_attack(X,Y,W) }.

%% When no attacks are discarded, cost is 0 (identity element)
%% Note: #sum over empty set naturally returns 0, but we make it explicit for consistency
extension_cost(0) :- not discarded_attack(_,_,_).

%% Budget constraint: Use constraint/ub.lp (Upper Bound regime)
