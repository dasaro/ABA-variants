%% WABA Core: Probabilistic Semiring + Sum Monoid
%% ================================================
%%
%% Weight Propagation (Probabilistic Semiring - Simplified):
%%   - Conjunction: average of probabilities (simplified product)
%%   - Identity: 100 (certainty)
%%   - Weights in [0,100] represent probability percentages
%%   - Note: This is a simplified approximation of true probabilistic inference
%%
%% Cost Aggregation (Sum Monoid):
%%   - Extension cost = sum of all discarded attack weights
%%   - Represents the "total probability cost" of discarded attacks

#include "../core_base.lp".
#include "../semiring/probabilistic.lp".
#include "../monoid/sum.lp".
