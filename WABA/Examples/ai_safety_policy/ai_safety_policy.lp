%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% AI SAFETY POLICY - Deployment Decision Under Safety Requirements
%%
%% STORY (ASYMMETRIC - Clear Approval with Minor Risk):
%% An AI system passes THREE critical safety checks (interpretability, fairness,
%% monitoring) but shows MINOR weakness in adversarial robustness (85% assurance
%% instead of ideal 95%). The regulator must decide: reject over minor robustness
%% gap (high cost), or approve with minimal risk acceptance (low cost, 85% is
%% still strong). Clear decision: approve with accepted minor robustness risk.
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
%%   WABA/constraint/lb_min.lp \
%%   WABA/examples/ai_safety_policy/ai_safety_policy.lp
%%
%% EXPECTED: Extension {assume_adversarial_robustness, assume_interpretability,
%%                      assume_fairness, assume_monitoring}
%% (All requirements hold, accept minor robustness gap at 85%, approval granted)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 60.

%% Budget constraint (requires constraint/lb_min.lp to be loaded)
budget(beta).

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

%% Safety requirement weights - ASYMMETRIC (3 pass, 1 minor issue)
weight(assume_adversarial_robustness, 95).  % Ideal: 95% needed
weight(assume_interpretability, 90).        % PASSED: fully transparent
weight(assume_fairness, 92).                % PASSED: no bias detected
weight(assume_monitoring, 88).              % PASSED: excellent oversight

%% Minor robustness gap violation (low cost to accept)
weight(minor_robustness_gap, 85).    % Still 85% assurance (strong, just below ideal)

%% Deployment decision weights
weight(approval_granted, 95).        % Strong approval if all critical checks pass

%% ============================================================================
%% RULES (Safety Requirements → Testing → Violations → Decisions)
%% ============================================================================

%% r1: Minor robustness gap detected (only violation that occurs)
head(r1, minor_robustness_gap).
% No body - this is the single finding: robustness at 85% (below 95% ideal)

%% r2: All four safety requirements met → approval granted
head(r2, approval_granted).
body(r2, assume_adversarial_robustness).  % Accept 85% robustness (minor gap)
body(r2, assume_interpretability).        % Fully transparent (passes)
body(r2, assume_fairness).                % No bias (passes)
body(r2, assume_monitoring).              % Excellent oversight (passes)

%% Simplified: Only robustness has minor issue, all others clearly pass

%% ============================================================================
%% CONTRARIES (Dimension-Specific Violations Defeat Requirements)
%% ============================================================================

% Only robustness has minor gap (85% vs 95% ideal)
contrary(assume_adversarial_robustness, minor_robustness_gap).
% Other requirements unattacked - all pass their checks

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/lb_min.lp
%% (minimum safety threshold ≥ β)
