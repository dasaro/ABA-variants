%% WABA Core: Boolean Semiring + Minimum Monoid
%% ==============================================
%%
%% Weight Propagation (Boolean Semiring):
%%   - Conjunction: minimum (logical AND)
%%   - Identity: 1 (true)
%%   - Weights in {0,1} represent truth values
%%
%% Cost Aggregation (Minimum Monoid):
%%   - Extension cost = minimum discarded attack weight
%%   - Represents the "cheapest" discarded attack

#include "../core_base.lp".
#include "../semiring/boolean.lp".
#include "../monoid/min.lp".
