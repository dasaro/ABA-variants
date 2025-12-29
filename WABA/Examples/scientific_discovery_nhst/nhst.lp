%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% NHST-STYLE HYPOTHESIS TESTING - Statistical Significance as Argumentation
%%
%% STORY:
%% A researcher tests null hypothesis H0 (no effect) against alternatives H1, H2
%% (effect exists). Statistical tests yield p-values; significant results
%% (p ≤ α) attack H0. Discarding an attack = ignoring strong statistical evidence.
%% We minimize total ignored evidence strength while deciding which hypothesis
%% to accept. Practical decisions require both statistical significance AND
%% effect size (mixed-body rules).
%%
%% WEIGHT INTERPRETATION:
%% Weights represent evidence strength = floor(100 * (1 - p)). Higher p-value
%% (weaker evidence) → lower weight. p=0.001 → weight=99 (very strong).
%% p=0.05 → weight=95 (marginally significant).
%%
%% SEMIRING: Tropical (sum/min)
%% JUSTIFICATION: Evidence strength accumulates across multiple independent tests.
%% When multiple tests reject H0, their evidential strength combines additively
%% (meta-analytic accumulation of evidence).
%%
%% MONOID: Sum
%% JUSTIFICATION: Extension cost = total strength of ignored evidence. Each
%% discarded significant result contributes its evidence strength to the total
%% ignored evidence budget.
%%
%% OPTIMIZATION: Minimize
%% JUSTIFICATION: Minimize total ignored evidence strength (evidential conservatism).
%%
%% BUDGET β: Upper bound on total ignored evidence strength.
%% β = 100 means "can ignore ≤100 units of evidence strength" (e.g., 1 very strong
%% result OR 2 moderate results).
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding a significant result = dismissing statistical evidence as
%% unreliable/spurious (cost = evidence strength). We sum how much evidence we
%% chose to disregard.
%%
%% USAGE:
%% clingo -n 0 --opt-mode=opt -c beta=100 -c alpha=5 \
%%   WABA/core/base.lp \
%%   WABA/semiring/tropical.lp \
%%   WABA/monoid/sum_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/examples/scientific_discovery_nhst/nhst.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 100.

%% Significance level α (as integer percentage: α=5 means p≤0.05)
#const alpha = 5.

%% ============================================================================
%% ASSUMPTIONS (Hypotheses Under Test)
%% ============================================================================

assumption(h0).  % Null hypothesis: no treatment effect
assumption(h1).  % Alternative: treatment increases performance
assumption(h2).  % Alternative: treatment decreases performance (side effects)

%% ============================================================================
%% WEIGHTS (Evidence Strength)
%% ============================================================================

%% Hypothesis weights (prior plausibility - for Tropical accumulation)
weight(h0, 40).  % Null has moderate prior (status quo)
weight(h1, 50).  % Treatment effect plausible
weight(h2, 60).  % Side effects less plausible but important to test

%% Test result weights (statistical evidence strength)
weight(test_performance_increase, 70).  % Test for positive effect
weight(test_safety_profile, 65).        % Test for adverse effects
weight(test_replication, 60).           % Independent replication

%% P-value derived atoms (evidence strength = floor(100 * (1-p)))
weight(pval_001_performance, 99).  % p=0.001 → very strong evidence
weight(pval_030_safety, 97).       % p=0.030 → moderate evidence
weight(pval_045_replication, 95).  % p=0.045 → marginally significant

%% Significance indicators (p ≤ α)
weight(significant_performance, 99).
weight(significant_safety, 97).
weight(significant_replication, 95).

%% Rejection tokens (significant result rejects H0)
weight(rejects_h0_performance, 99).
weight(rejects_h0_replication, 95).

%% Aggregate rejection
weight(rejected_h0, 100).  % H0 rejected by multiple significant tests

%% Mixed-body derived atoms
weight(effect_size_large, 80).          % Clinical significance (beyond stats)
weight(accept_practical_policy, 90).    % Policy decision requires both

%% ============================================================================
%% RULES (Tests → P-values → Significance → Rejections)
%% ============================================================================

%% r1-r3: Statistical tests always performed (observational facts)
head(r1, test_performance_increase).
head(r2, test_safety_profile).
head(r3, test_replication).

%% r4-r6: Tests yield p-values (observational outcomes)
head(r4, pval_001_performance).
body(r4, test_performance_increase).

head(r5, pval_030_safety).
body(r5, test_safety_profile).

head(r6, pval_045_replication).
body(r6, test_replication).

%% r7-r9: P-values ≤ α → significant results
head(r7, significant_performance).
body(r7, pval_001_performance).  % p=0.001 ≤ 0.05

head(r8, significant_safety).
body(r8, pval_030_safety).  % p=0.030 ≤ 0.05

head(r9, significant_replication).
body(r9, pval_045_replication).  % p=0.045 ≤ 0.05

%% r10-r11: Significant results generate rejection tokens for H0
head(r10, rejects_h0_performance).
body(r10, significant_performance).

head(r11, rejects_h0_replication).
body(r11, significant_replication).

%% r12: Aggregate rejection (multiple significant results → stronger case)
head(r12, rejected_h0).
body(r12, rejects_h0_performance).   % Weight 99
body(r12, rejects_h0_replication).   % Weight 95
% Tropical sum: 99 + 95 = 194 (cumulative evidence strength)

%% r13: Effect size assessment (statistical + practical significance)
head(r13, effect_size_large).
body(r13, significant_performance).
body(r13, test_replication).  % Confirmed by replication

%% r14: MIXED-BODY RULE - Practical policy acceptance requires both
%%      statistical significance (H1) AND clinical significance (effect_size_large)
head(r14, accept_practical_policy).
body(r14, h1).                    % Assumption (alternative hypothesis accepted)
body(r14, effect_size_large).     % Derived atom (clinical significance confirmed)

%% ============================================================================
%% CONTRARIES (Significant Results Defeat Null Hypothesis)
%% ============================================================================

contrary(h0, rejected_h0).  % Null hypothesis defeated by cumulative evidence

%% Note: H1 and H2 not directly attacked by statistical tests (only H0 tested).
%% To satisfy totality, we include contraries based on logical incompatibility:
contrary(h1, rejected_h1_by_h2).  % If H2 strongly supported, H1 defeated
contrary(h2, rejected_h2_by_h1).  % If H1 strongly supported, H2 defeated

%% r15-r16: Mutual exclusion of H1 and H2 (if one accepted with strong evidence, other defeated)
head(r15, rejected_h2_by_h1).
body(r15, accept_practical_policy).  % H1 accepted with strong effect

head(r16, rejected_h1_by_h2).
body(r16, significant_safety).  % Safety concerns (H2) significant
body(r16, h2).                  % H2 accepted

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub_sum.lp
%% (total ignored evidence ≤ β)
