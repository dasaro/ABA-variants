%% WABA Core: Fuzzy Semiring + Sum Monoid
%% ========================================
%%
%% Weight Propagation (Fuzzy Semiring):
%%   - Conjunction: minimum weight (pessimistic AND)
%%   - Identity: 100 (full truth degree)
%%   - Weights in [0,100] represent fuzzy truth degrees
%%
%% Cost Aggregation (Sum Monoid):
%%   - Extension cost = sum of all discarded attack weights
%%   - Represents the "total cost" of discarded attacks

#include "../core_base.lp".
#include "../semiring/fuzzy.lp".
#include "../monoid/sum.lp".
