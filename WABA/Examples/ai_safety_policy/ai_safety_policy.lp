%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% AI SAFETY POLICY - Deployment Decision Under Safety Requirements
%%
%% STORY:
%% A regulatory body must decide whether to approve an AI system for deployment.
%% Four defeasible safety requirements (assumptions) must be satisfied:
%% adversarial robustness, interpretability, fairness, and adequate monitoring.
%% Evidence suggests some requirements may be violated. The decision balances
%% minimum safety thresholds (maximin across dimensions) against deployment
%% benefits. Violations defeat safety requirements, forcing acceptance of
%% residual risk in some dimensions.
%%
%% WEIGHT INTERPRETATION:
%% Weights represent safety assurance level (0-100), where higher values
%% indicate MORE safety assurance. This is a REWARD interpretation (not cost).
%% When we discard a violation attack, we accept that dimension has lower
%% safety (losing the assurance weight).
%%
%% SEMIRING: Bottleneck (max/min)
%% JUSTIFICATION: System safety is determined by the weakest link in the
%% safety chain (worst-case dimension). Bottleneck propagation identifies
%% the limiting safety factor (max for conjunction = worst case, min for
%% disjunction = best alternative).
%%
%% MONOID: Min
%% JUSTIFICATION: Extension cost = MINIMUM safety assurance among discarded
%% violations. When we accept violations, the "cost" is the LOWEST safety
%% level we're willing to tolerate (maximin safety: maximize the minimum).
%%
%% OPTIMIZATION: Maximize
%% JUSTIFICATION: Weights represent rewards (safety assurance). We MAXIMIZE
%% minimum safety to find the deployment policy with the highest worst-case
%% safety guarantee (maximin safety).
%%
%% BUDGET β: Lower bound on minimum safety threshold.
%% β = 60 means "all dimensions must have ≥ 60 safety assurance"
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding a safety violation = accepting residual risk in that dimension
%% (at cost = safety assurance lost). The minimum across all accepted risks
%% determines the weakest safety dimension.
%%
%% USAGE:
%% clingo -n 0 --opt-mode=opt -c beta=60 \
%%   WABA/core/base.lp \
%%   WABA/semiring/bottleneck_cost.lp \
%%   WABA/monoid/min_maximization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/examples/ai_safety_policy/ai_safety_policy.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 60.

%% ============================================================================
%% ASSUMPTIONS (Defeasible Safety Requirements)
%% ============================================================================

assumption(assume_adversarial_robustness). % System resists adversarial inputs
assumption(assume_interpretability).       % Decisions are explainable
assumption(assume_fairness).               % No demographic bias
assumption(assume_monitoring).             % Ongoing oversight adequate

%% ============================================================================
%% WEIGHTS (Safety Assurance Level - REWARD interpretation)
%% ============================================================================

%% Safety requirement weights (assurance level 0-100, higher = more assured)
weight(assume_adversarial_robustness, 75).
weight(assume_interpretability, 70).
weight(assume_fairness, 80).
weight(assume_monitoring, 65).

%% Violation weights (safety assurance lost if violated)
weight(violates_robustness, 75).     % Robustness failure reduces assurance by 75
weight(violates_interpretability, 70). % Explainability failure reduces by 70
weight(violates_fairness, 80).       % Bias detected reduces by 80
weight(violates_monitoring, 65).     % Oversight inadequate reduces by 65

%% Deployment decision weights
weight(approval_granted, 85).
weight(approval_conditional, 70).

%% Evidence weights (testing results)
weight(test_results_robustness, 60).  % Robustness testing shows 60% assurance
weight(test_results_fairness, 50).    % Fairness testing shows 50% assurance

%% ============================================================================
%% RULES (Safety Requirements → Testing → Violations → Decisions)
%% ============================================================================

%% r1: Testing results (derived from evaluation process)
head(r1, test_results_robustness).
head(r2, test_results_fairness).

%% r3: Robustness assumption + weak test results → violation detected
head(r3, violates_robustness).
body(r3, assume_adversarial_robustness).
body(r3, test_results_robustness).
body(r3, threshold_not_met_robustness). % Testing below threshold

%% r4: Fairness assumption + weak test results → violation detected
head(r4, violates_fairness).
body(r4, assume_fairness).
body(r4, test_results_fairness).
body(r4, threshold_not_met_fairness).

%% r5: Interpretability assumption + black-box detection → violation
head(r5, violates_interpretability).
body(r5, assume_interpretability).
body(r5, black_box_detected).  % Model is not interpretable

%% r6: Monitoring assumption + insufficient oversight → violation
head(r6, violates_monitoring).
body(r6, assume_monitoring).
body(r6, oversight_gaps_found).

%% r7: Threshold checks (derived from test results vs. requirements)
head(r7, threshold_not_met_robustness).
body(r7, test_results_robustness).  % Testing shows <75% assurance needed

head(r8, threshold_not_met_fairness).
body(r8, test_results_fairness).    % Testing shows <80% assurance needed

%% r9: Model architecture analysis reveals black-box
head(r9, black_box_detected).
% No body - this is a finding from architecture review

%% r10: Monitoring assessment reveals gaps
head(r10, oversight_gaps_found).
% No body - this is a finding from oversight audit

%% r11: All safety requirements met → full approval
head(r11, approval_granted).
body(r11, assume_adversarial_robustness).
body(r11, assume_interpretability).
body(r11, assume_fairness).
body(r11, assume_monitoring).

%% r12: Some requirements met + monitoring → conditional approval
head(r12, approval_conditional).
body(r12, assume_monitoring).  % At least monitoring must hold
body(r12, some_requirements_met).

head(r13, some_requirements_met).
body(r13, assume_fairness).  % Fairness is critical

%% ============================================================================
%% CONTRARIES (Dimension-Specific Violations Defeat Requirements)
%% ============================================================================

contrary(assume_adversarial_robustness, violates_robustness).
contrary(assume_interpretability, violates_interpretability).
contrary(assume_fairness, violates_fairness).
contrary(assume_monitoring, violates_monitoring).

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/lb_min.lp
%% (minimum safety threshold ≥ β)
