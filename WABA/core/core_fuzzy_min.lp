%% WABA Core: Fuzzy Semiring + Minimum Monoid
%% ============================================
%%
%% Weight Propagation (Fuzzy Semiring):
%%   - Conjunction: minimum weight (pessimistic AND)
%%   - Identity: 100 (full truth degree)
%%   - Weights in [0,100] represent fuzzy truth degrees
%%
%% Cost Aggregation (Minimum Monoid):
%%   - Extension cost = minimum discarded attack weight
%%   - Represents the "cheapest" discarded attack

#include "../core_base.lp".
#include "../semiring/fuzzy.lp".
#include "../monoid/min.lp".
