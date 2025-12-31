%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RESOURCE ALLOCATION - Stakeholder Needs Under Budget Constraints
%%
%% STORY (ASYMMETRIC - Clear Priority):
%% A nonprofit can only fund TWO of four critical needs: emergency healthcare
%% (life-threatening), education (important), housing (significant), infrastructure
%% (deferrable). Healthcare has absolute priority (lives at stake). The choice
%% is between funding healthcare+education vs. healthcare+housing, where education
%% wins due to long-term impact. Infrastructure is clearly deferrable.
%%
%% WEIGHT INTERPRETATION:
%% Weights represent deprivation severity (0-100) if a need is unfunded.
%% Higher weights = more severe deprivation.
%%
%% SEMIRING: Tropical (sum/min)
%% JUSTIFICATION: Funding impact accumulates through beneficiary chains.
%% When multiple needs share beneficiaries, their impacts combine additively
%% (cumulative welfare improvement). Min for disjunction (best alternative).
%%
%% MONOID: Max
%% JUSTIFICATION: Extension cost = worst single deprivation (maximin equity).
%% We minimize the maximum deprivation to ensure the most deprived stakeholder
%% group is as well-off as possible (Rawlsian distributive justice).
%%
%% OPTIMIZATION: Minimize
%% JUSTIFICATION: Weights represent costs (deprivation severity). We minimize
%% worst-case deprivation.
%%
%% BUDGET β: Upper bound on worst deprivation allowed.
%% β = 50 means "no stakeholder group suffers deprivation > 50 severity"
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding an unfunded status = accepting that deprivation (at cost =
%% severity). The maximum across all accepted deprivations is the worst-case.
%%
%% USAGE:
%% clingo -n 0 --opt-mode=opt -c beta=50 \
%%   WABA/core/base.lp \
%%   WABA/semiring/tropical.lp \
%%   WABA/monoid/max_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/constraint/ub_max.lp \
%%   WABA/examples/resource_allocation/resource_allocation.lp
%%
%% EXPECTED: Extension {assume_need_healthcare, assume_need_education}
%% (Fund life-threatening healthcare + education, defer housing & infrastructure)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 50.

%% Budget constraint (requires constraint/ub_max.lp to be loaded)
budget(beta).

%% ============================================================================
%% ASSUMPTIONS (Stakeholder Needs)
%% ============================================================================

assumption(assume_need_education).      % Education funding requested
assumption(assume_need_healthcare).     % Healthcare funding requested
assumption(assume_need_housing).        % Housing funding requested
assumption(assume_need_infrastructure). % Infrastructure funding requested

%% ============================================================================
%% WEIGHTS (Deprivation Severity)
%% ============================================================================

%% Need weights (priority/urgency) - ASYMMETRIC HIERARCHY
weight(assume_need_education, 65).
weight(assume_need_healthcare, 95).   % Life-threatening - absolute priority
weight(assume_need_housing, 50).
weight(assume_need_infrastructure, 25).  % Deferrable - lowest priority

%% Unfunded deprivation weights (severity if need not met) - CLEAR GRADATION
weight(unfunded_education, 45).       % Moderate: education delay acceptable
weight(unfunded_healthcare, 95).      % Critical: health deprivation life-threatening
weight(unfunded_housing, 30).         % Manageable: temporary housing solutions exist
weight(unfunded_infrastructure, 15).  % Low: infrastructure can wait

%% Funding outcome weights
weight(funded_education, 30).
weight(funded_healthcare, 40).
weight(funded_housing, 35).
weight(funded_infrastructure, 25).

%% ============================================================================
%% RULES (Needs → Allocations → Unfunded States)
%% ============================================================================

%% r1: Education need → funded if resources available
head(r1, funded_education).
body(r1, assume_need_education).
body(r1, sufficient_resources_education).

%% r2: Healthcare need → funded if resources available
head(r2, funded_healthcare).
body(r2, assume_need_healthcare).
body(r2, sufficient_resources_healthcare).

%% r3: Housing need → funded if resources available
head(r3, funded_housing).
body(r3, assume_need_housing).
body(r3, sufficient_resources_housing).

%% r4: Education need + insufficient resources → unfunded
head(r4, unfunded_education).
body(r4, assume_need_education).
body(r4, insufficient_resources_education).

%% r5: Healthcare need + insufficient resources → unfunded
head(r5, unfunded_healthcare).
body(r5, assume_need_healthcare).
body(r5, insufficient_resources_healthcare).

%% r6: Housing need + insufficient resources → unfunded
head(r6, unfunded_housing).
body(r6, assume_need_housing).
body(r6, insufficient_resources_housing).

%% r7: Infrastructure need + insufficient resources → unfunded
head(r7, unfunded_infrastructure).
body(r7, assume_need_infrastructure).
body(r7, insufficient_resources_infrastructure).

%% r8-r10: Resource constraints (can only fund healthcare + ONE other)
%% Healthcare has absolute priority - if education+housing both claimed, education loses
head(r8, insufficient_resources_education).
body(r8, assume_need_healthcare).
body(r8, assume_need_housing).  % Education blocked if healthcare+housing claimed

%% Housing blocked if healthcare+education claimed
head(r9, insufficient_resources_housing).
body(r9, assume_need_healthcare).
body(r9, assume_need_education).

%% Infrastructure blocked if healthcare+any other claimed
head(r10, insufficient_resources_infrastructure).
body(r10, assume_need_healthcare).
body(r10, assume_need_education).

head(r11, insufficient_resources_infrastructure).
body(r11, assume_need_healthcare).
body(r11, assume_need_housing).

%% Healthcare NEVER insufficient (absolute priority)
% No rule derives insufficient_resources_healthcare

%% ============================================================================
%% CONTRARIES (Unfunded Needs Defeat Assumptions)
%% ============================================================================

contrary(assume_need_education, unfunded_education).
contrary(assume_need_healthcare, unfunded_healthcare).
contrary(assume_need_housing, unfunded_housing).
contrary(assume_need_infrastructure, unfunded_infrastructure).

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub_max.lp
%% (worst deprivation ≤ β)
