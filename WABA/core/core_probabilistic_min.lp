%% WABA Core: Probabilistic Semiring + Minimum Monoid
%% ====================================================
%%
%% Weight Propagation (Probabilistic/Viterbi Semiring):
%%   - Conjunction: multiplication (joint probability)
%%   - Identity: 100 (certainty)
%%   - Weights in [0,100] represent probabilities (scaled)
%%
%% Cost Aggregation (Minimum Monoid):
%%   - Extension cost = minimum discarded attack weight
%%   - Represents the "cheapest" discarded attack

#include "../core_base.lp".
#include "../semiring/probabilistic.lp".
#include "../monoid/min.lp".
