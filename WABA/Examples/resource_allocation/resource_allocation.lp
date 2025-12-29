%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% RESOURCE ALLOCATION - Stakeholder Needs Under Budget Constraints
%%
%% STORY:
%% A nonprofit must allocate limited funding across competing stakeholder needs
%% (education, healthcare, housing, infrastructure). Each need is a defeasible
%% claim (assumption) that generates allocation decisions. When needs exceed
%% available resources, some must remain unfunded (contraries), creating
%% deprivation. We minimize worst-case deprivation (maximin equity).
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
%%   WABA/examples/resource_allocation/resource_allocation.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 50.

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

%% Need weights (priority/urgency)
weight(assume_need_education, 70).
weight(assume_need_healthcare, 80).
weight(assume_need_housing, 75).
weight(assume_need_infrastructure, 60).

%% Unfunded deprivation weights (severity if need not met)
weight(unfunded_education, 70).      % Severe: education deprivation
weight(unfunded_healthcare, 80).     % Most severe: health deprivation
weight(unfunded_housing, 75).        % Very severe: housing deprivation
weight(unfunded_infrastructure, 60). % Moderate: infrastructure deprivation

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

%% r8-r11: Resource sufficiency checks (modeling scarcity)
%% If 3+ needs are claimed, at least one must be unfunded
head(r8, insufficient_resources_education).
body(r8, assume_need_healthcare).
body(r8, assume_need_housing).
body(r8, assume_need_infrastructure).

head(r9, insufficient_resources_healthcare).
body(r9, assume_need_education).
body(r9, assume_need_housing).
body(r9, assume_need_infrastructure).

head(r10, insufficient_resources_housing).
body(r10, assume_need_education).
body(r10, assume_need_healthcare).
body(r10, assume_need_infrastructure).

head(r11, insufficient_resources_infrastructure).
body(r11, assume_need_education).
body(r11, assume_need_healthcare).
body(r11, assume_need_housing).

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
