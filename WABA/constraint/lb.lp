%% WABA Lower Bound (LB) Budget Constraint
%% =========================================
%%
%% ⚠️  IMPORTANT: This is a DOCUMENTATION file only.
%% ⚠️  Use the monoid-specific files instead:
%%
%%     constraint/lb_sum.lp    - For SUM monoid (total cost ≥ β)
%%     constraint/lb_max.lp    - For MAX monoid (worst-case cost ≥ β)
%%     constraint/lb_min.lp    - For MIN monoid (quality threshold ≥ β) ⭐ RECOMMENDED
%%     constraint/lb_count.lp  - For COUNT monoid (number of discards ≥ β)
%%
%% WHY MONOID-SPECIFIC FILES?
%% ==========================
%% All constraints check discarded_attack/3 directly, which means:
%% - If you load a generic lb.lp, ALL aggregate checks fire simultaneously
%% - This causes constraint interference (e.g., COUNT < β rejects even when using MIN monoid)
%% - Monoid-specific files ensure only the correct aggregate is checked
%%
%% USAGE EXAMPLES
%% ==============
%%
%% MIN monoid with quality threshold β=10 (most common use case):
%%   clingo -c beta=10 core/base.lp semiring/tropical.lp monoid/min_minimization.lp \
%%          filter/standard.lp constraint/lb_min.lp semantics/stable.lp framework.lp
%%
%% SUM monoid with minimum total cost β=50 (unusual):
%%   clingo -c beta=50 core/base.lp semiring/tropical.lp monoid/sum_minimization.lp \
%%          filter/standard.lp constraint/lb_sum.lp semantics/stable.lp framework.lp
%%
%% COUNT monoid with minimum 2 discarded attacks (unusual):
%%   clingo -c beta=2 core/base.lp semiring/tropical.lp monoid/count_minimization.lp \
%%          filter/standard.lp constraint/lb_count.lp semantics/stable.lp framework.lp
%%
%% SEMANTICS BY MONOID
%% ===================
%%
%% SUM:   Lower bound on total cost (unusual - requires minimum spending)
%% MAX:   Lower bound on worst-case cost (unusual - requires expensive discards)
%% MIN:   ⭐ Quality threshold (standard - requires minimum quality floor)
%% COUNT: Lower bound on number of discarded attacks (unusual - requires minimum discards)
%%
%% NOTE: Lower bounds are most commonly used with MIN monoid for quality thresholds.
%%       Other monoids rarely need lower bounds in practice.
%%
%% DEFAULT BETA VALUES
%% ===================
%% All lb_*.lp files default to β = #inf (no minimum, permissive)
%% Override with: -c beta=N

%% This file intentionally contains no constraints to prevent accidental misuse.
%% Load the appropriate monoid-specific file instead.
