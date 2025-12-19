%% WABA Core: Tropical Semiring + Sum Monoid
%% ==========================================
%%
%% Weight Propagation (Tropical Semiring):
%%   - Conjunction: minimum weight (weakest link)
%%   - Identity: #sup (infinity)
%%   - Original WABA weight propagation
%%
%% Cost Aggregation (Sum Monoid):
%%   - Extension cost = sum of all discarded attack weights
%%   - Represents the "total cost" of all discarded attacks
%%   - Different from original WABA which uses max

#include "../core_base.lp".
#include "../semiring/tropical.lp".
#include "../monoid/sum.lp".
