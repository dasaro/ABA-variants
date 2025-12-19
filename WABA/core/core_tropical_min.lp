%% WABA Core: Tropical Semiring + Minimum Monoid
%% ===============================================
%%
%% Weight Propagation (Tropical Semiring):
%%   - Conjunction: minimum weight (weakest link)
%%   - Identity: #sup (infinite weight for assumptions)
%%
%% Cost Aggregation (Minimum Monoid):
%%   - Extension cost = minimum discarded attack weight
%%   - Represents the "cheapest" discarded attack

#include "../core_base.lp".
#include "../semiring/tropical.lp".
#include "../monoid/min.lp".
