%% WABA Core: Boolean Semiring + Sum Monoid
%% ==========================================
%%
%% Weight Propagation (Boolean Semiring):
%%   - Conjunction: minimum (logical AND)
%%   - Identity: 1 (true)
%%   - Weights in {0,1} represent truth values
%%
%% Cost Aggregation (Sum Monoid):
%%   - Extension cost = sum of all discarded attack weights
%%   - Represents the "total cost" of discarded attacks

#include "../core_base.lp".
#include "../semiring/boolean.lp".
#include "../monoid/sum.lp".
