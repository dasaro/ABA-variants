%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LEGAL PRECEDENT REASONING - Non-Compete Clause Enforceability
%%
%% STORY (ASYMMETRIC - Narrow Scope Clearly Enforceable):
%% A court evaluates a non-compete clause with TWO key provisions: geographic
%% scope (narrow: 50-mile radius) and duration (short: 1 year). A weak precedent
%% (low authority) suggests even narrow restrictions may be void, but strong
%% precedent (Supreme Court) clearly allows reasonable restrictions. The narrow,
%% time-limited clause is clearly enforceable under binding precedent.
%%
%% WEIGHT INTERPRETATION:
%% Weights represent precedent authority strength (0-100), where higher values
%% indicate more binding authority (e.g., Supreme Court > Circuit Court).
%% When we override a precedent (discard its attack), we "distinguish the case"
%% at a cost equal to the precedent's authority.
%%
%% SEMIRING: Tropical (sum/min)
%% JUSTIFICATION: Legal authority accumulates through citation chains.
%% When multiple precedents support a conclusion, their authority combines
%% additively (cumulative legal support). This models how legal arguments
%% gain strength by citing multiple authoritative sources.
%%
%% MONOID: Sum
%% JUSTIFICATION: Extension cost = total deviation from binding precedent.
%% Each time we override a precedent (distinguish it), we incur a deviation
%% cost equal to its authority weight. The sum represents total legal burden
%% of the argument's departures from established law.
%%
%% OPTIMIZATION: Maximize (with cost minimization)
%% JUSTIFICATION: We maximize legal strength (explanatory power) while
%% minimizing precedent deviation. In this encoding, we MINIMIZE deviation
%% cost using sum_minimization.lp, which is equivalent to MAXIMIZING legal
%% strength (since lower deviation = stronger legal position).
%%
%% BUDGET β: Upper bound on total precedent deviation allowed.
%% β = 150 means "total deviation ≤ 150 authority units"
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding a precedent attack = "distinguishing the case" (arguing this
%% case differs from the precedent, so the precedent doesn't apply).
%% Cost = precedent authority weight (higher authority = harder to distinguish).
%%
%% USAGE:
%% clingo -n 0 --opt-mode=opt -c beta=150 \
%%   WABA/core/base.lp \
%%   WABA/semiring/tropical.lp \
%%   WABA/monoid/sum_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/constraint/ub_sum.lp \
%%   WABA/examples/legal_precedent/legal_precedent.lp
%%
%% EXPECTED: Extension {assume_narrow_scope, assume_short_duration, assume_legitimate_interest}
%% (All assumptions hold, weak precedent distinguished, clause enforceable)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 150.

%% Budget constraint (requires constraint/ub_sum.lp to be loaded)
budget(beta).

%% ============================================================================
%% ASSUMPTIONS (Defeasible Legal Interpretations)
%% ============================================================================

assumption(assume_narrow_scope).        % Non-compete limited to 50-mile radius (reasonable)
assumption(assume_short_duration).      % 1-year restriction (clearly reasonable)
assumption(assume_legitimate_interest). % Employer has trade secrets to protect

%% ============================================================================
%% WEIGHTS (Precedent Authority Strength)
%% ============================================================================

%% Assumption weights - ASYMMETRIC (narrow/short clearly reasonable)
weight(assume_narrow_scope, 80).         % Strong: narrow scope is reasonable
weight(assume_short_duration, 75).       % Strong: 1 year is clearly reasonable
weight(assume_legitimate_interest, 85).  % Strong: trade secrets are protectable

%% Weak precedent challenging narrow scope (low authority - easily distinguished)
weight(weak_precedent_anti_noncompete, 20).  % Low authority: general anti-restriction view

%% Conclusion weights
weight(conclusion_enforceable, 90).      % Strong conclusion if all assumptions hold

%% ============================================================================
%% RULES (Legal Reasoning Chains)
%% ============================================================================

%% r1: All three reasonable assumptions → enforceable conclusion
head(r1, conclusion_enforceable).
body(r1, assume_narrow_scope).
body(r1, assume_short_duration).
body(r1, assume_legitimate_interest).

%% r2: Weak anti-restriction precedent (always holds as a minority view)
head(r2, weak_precedent_anti_noncompete).
% No body - this represents a weak, outlier precedent that's easily distinguished

%% ============================================================================
%% CONTRARIES (Precedent-Based Defeats)
%% ============================================================================

% Weak precedent attacks narrow scope (but easily distinguished due to low authority)
contrary(assume_narrow_scope, weak_precedent_anti_noncompete).
% Other assumptions unattacked - clearly reasonable

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub_sum.lp
%% (total precedent deviation ≤ β)
