%% WABA Upper Bound (UB) Budget Constraint
%% =========================================
%%
%% ⚠️  IMPORTANT: This is a DOCUMENTATION file only.
%% ⚠️  Use the monoid-specific files instead:
%%
%%     constraint/ub_sum.lp    - For SUM monoid (total cost ≤ β)
%%     constraint/ub_max.lp    - For MAX monoid (worst-case cost ≤ β)
%%     constraint/ub_min.lp    - For MIN monoid (best-case cost ≤ β)
%%     constraint/ub_count.lp  - For COUNT monoid (number of discards ≤ β)
%%
%% WHY MONOID-SPECIFIC FILES?
%% ==========================
%% All constraints check discarded_attack/3 directly, which means:
%% - If you load a generic ub.lp, ALL aggregate checks fire simultaneously
%% - This causes constraint interference (e.g., COUNT > β rejects even when using SUM monoid)
%% - Monoid-specific files ensure only the correct aggregate is checked
%%
%% USAGE EXAMPLES
%% ==============
%%
%% SUM monoid with upper bound β=100:
%%   clingo -c beta=100 core/base.lp semiring/tropical.lp monoid/sum_minimization.lp \
%%          filter/standard.lp constraint/ub_sum.lp semantics/stable.lp framework.lp
%%
%% MAX monoid with upper bound β=50:
%%   clingo -c beta=50 core/base.lp semiring/tropical.lp monoid/max_minimization.lp \
%%          filter/standard.lp constraint/ub_max.lp semantics/stable.lp framework.lp
%%
%% COUNT monoid with upper bound β=3 (max 3 discarded attacks):
%%   clingo -c beta=3 core/base.lp semiring/tropical.lp monoid/count_minimization.lp \
%%          filter/standard.lp constraint/ub_count.lp semantics/stable.lp framework.lp
%%
%% SEMANTICS BY MONOID
%% ===================
%%
%% SUM:   Upper bound on total cost (standard cost ceiling)
%% MAX:   Upper bound on worst-case cost (no single attack > β)
%% MIN:   Upper bound on best-case cost (unusual - use lb_min.lp for quality threshold)
%% COUNT: Upper bound on number of discarded attacks (budget = attack quota)
%%
%% DEFAULT BETA VALUES
%% ===================
%% All ub_*.lp files default to β = #sup (no limit, permissive)
%% Override with: -c beta=N

%% This file intentionally contains no constraints to prevent accidental misuse.
%% Load the appropriate monoid-specific file instead.
