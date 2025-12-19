%% WABA Core: Boolean Semiring + Maximum Monoid
%% =============================================
%%
%% Weight Propagation (Boolean Semiring):
%%   - Conjunction: boolean AND (all body elements must be 1)
%%   - Identity: 1 (true)
%%   - Weights are binary: 0 (false) or 1 (true)
%%   - Classical propositional logic
%%
%% Cost Aggregation (Maximum Monoid):
%%   - Extension cost = maximum discarded attack weight
%%   - With binary weights, this is either 0 or 1

#include "../core_base.lp".
#include "../semiring/boolean.lp".
#include "../monoid/max.lp".
