%% Sum Monoid for Cost Aggregation
%% Monoid: (ℝ, +, 0)
%% - Operation: sum (addition)
%% - Identity: 0
%%
%% Extension cost = sum of all discarded attack weights
%% This represents the "total cost" of all discarded attacks.
%%
%% Note: With multiple derivations of the same attack via different rules,
%% each derivation contributes its weight to the sum.
%% The tuple (W, X, Y) ensures each unique attack instance is counted.
%%
%% UNWEIGHTED ATOMS: Default weight = #sup (infinity)
%% Rationale: With sum monoid, hardest-to-discard = largest weight
%% - extension_cost = sum(#sup, ...) = #sup → infinitely expensive
%% - Can only discard if budget = #sup (unbounded)
%% - Compatible semirings: fuzzy, probabilistic (min has identity #sup)
%%
supported_with_weight(X,#sup) :-
    assumption(X), in(X), not weight(X,_).

%% Extension cost is the sum of all discarded attack weights
%% Only compute aggregate when discarded attacks exist
extension_cost(C) :- discarded_attack(_,_,_), C = #sum{ W, X, Y : discarded_attack(X,Y,W) }.

%% When no attacks are discarded, cost is 0 (identity element)
%% Note: #sum over empty set naturally returns 0, but we make it explicit for consistency
extension_cost(0) :- not discarded_attack(_,_,_).
