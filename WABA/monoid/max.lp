%% Maximum Cost Monoid for Cost Aggregation
%% Monoid: (ℝ ∪ {∞}, max, 0)
%% - Operation: maximum
%% - Identity: 0 (no discarded attacks = no cost)
%%
%% Extension cost = maximum weight among all discarded attacks
%% This represents the "most expensive" attack that was discarded.
%% When no attacks are discarded, the cost is 0 (no cost incurred).
%%
%% Note: This replaces the previous behavior where empty aggregates yielded #inf.
%% In semirings with bounded ranges (like fuzzy [0,100]), having #inf breaks
%% semantic consistency. Using 0 as the identity means "no discarded attacks = no cost".

%% Extension cost is the maximum discarded attack weight
%% Only compute aggregate when discarded attacks exist
extension_cost(C) :- discarded_attack(_,_,_), C = #max{ W, X, Y : discarded_attack(X,Y,W) }.

%% When no attacks are discarded, cost is 0 (identity element)
extension_cost(0) :- not discarded_attack(_,_,_).
