%% WABA Core: Fuzzy Semiring + Maximum Monoid
%% ============================================
%%
%% Weight Propagation (Fuzzy Semiring):
%%   - Conjunction: minimum weight (pessimistic AND)
%%   - Identity: 100 (full truth degree)
%%   - Weights in [0,100] represent fuzzy truth degrees
%%
%% Cost Aggregation (Maximum Monoid):
%%   - Extension cost = maximum discarded attack weight
%%   - Represents the "most expensive" discarded attack

#include "../core_base.lp".
#include "../semiring/fuzzy.lp".
#include "../monoid/max.lp".
