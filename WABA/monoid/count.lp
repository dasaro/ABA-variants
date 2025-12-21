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

%% DEFAULT WEIGHTS: Now defined in semiring files (moved from here)
%% - Semirings assign defaults using disjunction identity
%% - All weight assignment is now semiring responsibility
%% - Monoids only handle cost aggregation
%% - COUNT is weight-agnostic anyway (only counts, ignores weights)

%% Count aggregation: number of discarded attacks
extension_cost(C) :- C = #count{ X,Y : discarded_attack(X,Y,_) }.

%% No discards: Use #sup (infinite cost in UB semantics, best quality in LB semantics)
%% NOTE: For plain ABA, constraints must handle #sup specially
%% - UB constraint: #sup means "no budget can afford discarding nothing" (paradox - needs fix)
%% - LB constraint: #sup means "best possible quality" (correct semantics)
extension_cost(#sup) :- not discarded_attack(_,_,_).

%% Budget constraint: Use constraint/ub.lp (Upper Bound regime)
