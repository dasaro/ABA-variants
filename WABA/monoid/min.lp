%% Minimum Cost Monoid for Cost Aggregation
%% Monoid: (ℝ ∪ {∞}, min, 0)
%% - Operation: minimum
%% - Identity: 0 (no discarded attacks = no cost)
%%
%% Extension cost = minimum weight among all discarded attacks
%% This represents the "cheapest" attack that was discarded.
%% When no attacks are discarded, the cost is 0 (no cost incurred).
%%
%% Note: This replaces the previous behavior where empty aggregates yielded #sup.
%% Using 0 as the identity maintains semantic consistency with bounded semirings
%% like fuzzy [0,100].

%% Extension cost is the minimum discarded attack weight
%% Only compute aggregate when discarded attacks exist
extension_cost(C) :- discarded_attack(_,_,_), C = #min{ W, X, Y : discarded_attack(X,Y,W) }.

%% When no attacks are discarded, cost is 0 (identity element)
extension_cost(0) :- not discarded_attack(_,_,_).
