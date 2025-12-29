%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% MORAL DILEMMA - Duty Conflicts in Medical Ethics (Trolley-Type Scenario)
%%
%% STORY:
%% A physician faces a trolley-problem-like scenario: four defeasible moral
%% duties (beneficence, nonmaleficence, autonomy, justice) guide action.
%% An intervention (sacrifice_one) would save five patients but requires
%% sacrificing one patient without consent. Inaction (do_nothing) respects
%% autonomy but results in five deaths. Each duty generates action
%% recommendations that violate other duties, forcing moral trade-offs.
%%
%% WEIGHT INTERPRETATION:
%% Weights represent moral wrongness severity (0-100) of violating each duty.
%% Higher weights = more serious moral violation.
%%
%% SEMIRING: Gödel (min/max)
%% JUSTIFICATION: An action's moral permissibility is only as strong as
%% the weakest duty in its justification chain (weakest-link deontology).
%% The moral strength of an action is limited by the weakest supporting duty.
%%
%% MONOID: Max
%% JUSTIFICATION: Extension cost = worst single duty violation.
%% We adopt lexical priority: minimize the worst moral wrongness
%% (least-unjust action under lexicographic ordering).
%%
%% OPTIMIZATION: Minimize
%% JUSTIFICATION: Weights represent costs (wrongness). We minimize to
%% find the action with the least worst moral violation.
%%
%% BUDGET β: Upper bound on worst duty violation allowed.
%% β = 40 means "no duty violation above 40 wrongness severity"
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding a duty violation = accepting that moral cost (committing
%% that moral wrong) at cost = violation severity.
%%
%% USAGE:
%% clingo -n 0 --opt-mode=opt -c beta=40 \
%%   WABA/core/base.lp \
%%   WABA/semiring/godel.lp \
%%   WABA/monoid/max_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/examples/moral_dilemma/moral_dilemma.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 40.

%% ============================================================================
%% ASSUMPTIONS (Defeasible Moral Duties)
%% ============================================================================

assumption(assume_duty_beneficence).     % Maximize patient welfare (save lives)
assumption(assume_duty_nonmaleficence).  % Do no harm (primum non nocere)
assumption(assume_duty_autonomy).        % Respect patient consent
assumption(assume_duty_justice).         % Fair distribution of care

%% ============================================================================
%% WEIGHTS (Moral Wrongness Severity)
%% ============================================================================

%% Duty assumption weights (prima facie strength before violations)
weight(assume_duty_beneficence, 80).
weight(assume_duty_nonmaleficence, 85).
weight(assume_duty_autonomy, 75).
weight(assume_duty_justice, 70).

%% Violation weights (severity of moral wrongness)
weight(violates_beneficence, 80).        % Failing to maximize welfare
weight(violates_nonmaleficence, 85).     % Actively causing harm
weight(violates_autonomy, 75).           % Violating consent
weight(violates_justice, 70).            % Unfair treatment

%% Action recommendation weights
weight(recommend_sacrifice_one, 60).
weight(recommend_inaction, 50).

%% Situational fact weights
weight(situational_five_at_risk, 90).    % Five patients will die without intervention
weight(situational_one_healthy, 50).     % One healthy person available for sacrifice

%% ============================================================================
%% RULES (Duties → Actions → Violations)
%% ============================================================================

%% r1: Situational facts (always hold in this scenario)
head(r1, situational_five_at_risk).
head(r2, situational_one_healthy).

%% r3: Beneficence + five at risk → recommends saving them (sacrifice one)
head(r3, recommend_sacrifice_one).
body(r3, assume_duty_beneficence).
body(r3, situational_five_at_risk).

%% r4: Nonmaleficence → recommends inaction (do no harm)
head(r4, recommend_inaction).
body(r4, assume_duty_nonmaleficence).

%% r5: Sacrifice action + autonomy duty → violates autonomy (no consent)
head(r5, violates_autonomy).
body(r5, recommend_sacrifice_one).
body(r5, assume_duty_autonomy).

%% r6: Sacrifice action → violates nonmaleficence (actively harms one)
head(r6, violates_nonmaleficence).
body(r6, recommend_sacrifice_one).

%% r7: Inaction + beneficence duty → violates beneficence (fails to save five)
head(r7, violates_beneficence).
body(r7, recommend_inaction).
body(r7, assume_duty_beneficence).

%% r8: Inaction + justice duty + five at risk → violates justice (unfair to five)
head(r8, violates_justice).
body(r8, recommend_inaction).
body(r8, assume_duty_justice).
body(r8, situational_five_at_risk).

%% r9: Sacrifice + justice duty → violates justice (unfair to one)
head(r9, violates_justice).
body(r9, recommend_sacrifice_one).
body(r9, assume_duty_justice).
body(r9, situational_one_healthy).

%% ============================================================================
%% CONTRARIES (Duty-Specific Violations Defeat Duties)
%% ============================================================================

contrary(assume_duty_autonomy, violates_autonomy).
contrary(assume_duty_nonmaleficence, violates_nonmaleficence).
contrary(assume_duty_beneficence, violates_beneficence).
contrary(assume_duty_justice, violates_justice).

%% ============================================================================
%% BUDGET CONSTRAINT (Worst Duty Violation ≤ β)
%% ============================================================================

%% The max_minimization.lp monoid defines extension_cost(C) = max discarded attack weight.
%% We enforce: extension_cost ≤ beta (worst duty violation ≤ β)

:- extension_cost(C), C > beta.

%% ============================================================================
%% BUDGET FACT (Needed by core/base.lp)
%% ============================================================================

budget(beta).
