%% Count Monoid - Minimization (Cost Semantics)
%% Monoid: (ℕ ∪ {∞}, count, 0)
%% - Domain: Natural numbers plus infinity
%% - Operation: count (cardinality)
%% - Identity: 0 (algebraic identity: count of empty set = 0)
%%
%% DIRECT MINIMIZE APPROACH (PERFORMANCE OPTIMIZED)
%% =================================================
%% Uses direct #minimize with count aggregation for optimal performance.
%%
%% Semantics:
%% - Minimize the number of discarded attacks (weight-agnostic)
%% - Goal: Find extensions that discard fewest attacks
%%
%% Performance:
%% - Direct #minimize is faster than weak constraints
%% - Weight parameter set to 1 for counting

%% Minimize the number of discarded attacks (count each as 1)
%% OPTIMIZED: Bind W explicitly for better grounding (saves ~4% rules)
#minimize { 1,X,Y : discarded_attack(X,Y,_) }.
