%% WABA Core: Tropical Semiring + Maximum Monoid
%% ===============================================
%% This configuration matches the original WABA behavior.
%%
%% Weight Propagation (Tropical Semiring):
%%   - Conjunction: minimum weight (weakest link)
%%   - Identity: #sup (infinite weight for assumptions)
%%
%% Cost Aggregation (Maximum Monoid):
%%   - Extension cost = maximum discarded attack weight
%%   - Represents the "most expensive" discarded attack

#include "../core_base.lp".
#include "../semiring/tropical.lp".
#include "../monoid/max.lp".
