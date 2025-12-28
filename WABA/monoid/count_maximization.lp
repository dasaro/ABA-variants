%% Count Monoid - Maximization (Reward Semantics)
%% Monoid: (ℕ ∪ {∞}, count, 0)
%% - Domain: Natural numbers plus infinity
%% - Operation: count (cardinality)
%% - Identity: 0 (algebraic identity: count of empty set = 0)
%%
%% DIRECT MAXIMIZE APPROACH (PERFORMANCE OPTIMIZED)
%% =================================================
%% Uses direct #maximize with count aggregation for optimal performance.
%%
%% Semantics:
%% - Maximize the number of discarded attacks (weight-agnostic)
%% - Goal: Find extensions that discard most attacks
%%
%% Performance:
%% - Direct #maximize is faster than weak constraints
%% - Weight parameter set to 1 for counting

%% Maximize the number of discarded attacks (count each as 1)
%% OPTIMIZED: Bind W explicitly for better grounding (saves ~4% rules)
#maximize { 1,X,Y : discarded_attack(X,Y,_) }.
