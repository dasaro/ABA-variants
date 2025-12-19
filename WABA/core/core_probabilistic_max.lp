%% WABA Core: Probabilistic Semiring + Maximum Monoid
%% ====================================================
%%
%% Weight Propagation (Probabilistic/Viterbi Semiring):
%%   - Conjunction: multiplication (joint probability)
%%   - Identity: 100 (certainty)
%%   - Weights in [0,100] represent probabilities (scaled)
%%
%% Cost Aggregation (Maximum Monoid):
%%   - Extension cost = maximum discarded attack weight
%%   - Represents the "most expensive" discarded attack

#include "../core_base.lp".
#include "../semiring/probabilistic.lp".
#include "../monoid/max.lp".
