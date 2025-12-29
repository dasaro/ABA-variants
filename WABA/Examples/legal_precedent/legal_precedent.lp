%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% LEGAL PRECEDENT REASONING - Non-Compete Clause Enforceability
%%
%% STORY:
%% A court must decide whether to enforce a non-compete clause. The decision
%% depends on defeasible legal interpretations (assumptions) of contract terms,
%% which when combined with established binding precedents (derived atoms),
%% yield legal conclusions. Precedents can defeat interpretations by establishing
%% contrary legal principles (e.g., geographic/temporal limits on non-competes).
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
%%   WABA/examples/legal_precedent/legal_precedent.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 150.

%% ============================================================================
%% ASSUMPTIONS (Defeasible Legal Interpretations)
%% ============================================================================

assumption(assume_broad_scope).       % Non-compete covers entire industry
assumption(assume_long_duration).     % 3-year restriction is reasonable
assumption(assume_legitimate_interest). % Employer has protectable interest

%% ============================================================================
%% WEIGHTS (Precedent Authority Strength)
%% ============================================================================

%% Assumption weights (strength of interpretation before precedent challenge)
weight(assume_broad_scope, 40).
weight(assume_long_duration, 35).
weight(assume_legitimate_interest, 50).

%% Precedent weights (authority strength - higher = more binding)
weight(precedent_geographic_limit, 80).  % Strong precedent: geographic limits required
weight(precedent_temporal_limit, 70).    % Strong precedent: temporal limits required
weight(conclusion_void_overbroad, 90).   % Very strong: void if overreaching

%% Derived conclusion weights
weight(conclusion_enforceable, 60).

%% ============================================================================
%% RULES (Legal Reasoning Chains)
%% ============================================================================

%% r1: Broad scope interpretation → derives geographic limit precedent
%% (Mixed body: assumption + legal doctrine)
head(r1, precedent_geographic_limit).
body(r1, assume_broad_scope).
body(r1, established_doctrine_limits). % Derived: doctrine requires limits

%% r2: Long duration interpretation → derives temporal limit precedent
head(r2, precedent_temporal_limit).
body(r2, assume_long_duration).
body(r2, established_doctrine_limits).

%% r3: Broad scope + long duration → conclusion of overreach (void)
head(r3, conclusion_void_overbroad).
body(r3, assume_broad_scope).
body(r3, assume_long_duration).

%% r4: Legitimate interest + limited scope → enforceable conclusion
head(r4, conclusion_enforceable).
body(r4, assume_legitimate_interest).
body(r4, geographic_limited).  % Derived: scope is geographically limited
body(r4, temporal_limited).    % Derived: duration is temporally limited

%% r5: Established legal doctrine (always holds, models background law)
head(r5, established_doctrine_limits).
% No body - this is a "fact" of established law

%% r6: Geographic limiting conditions (derives from non-broad scope)
%% This creates a logical dependency: if broad scope is defeated, limits apply
head(r6, geographic_limited).
body(r6, precedent_geographic_limit).

%% r7: Temporal limiting conditions
head(r7, temporal_limited).
body(r7, precedent_temporal_limit).

%% ============================================================================
%% CONTRARIES (Precedent-Based Defeats)
%% ============================================================================

contrary(assume_broad_scope, precedent_geographic_limit).
contrary(assume_long_duration, precedent_temporal_limit).
contrary(assume_legitimate_interest, conclusion_void_overbroad).

%% ============================================================================
%% BUDGET CONSTRAINT (Total Deviation ≤ β)
%% ============================================================================

%% The sum_minimization.lp monoid defines extension_cost(C) = sum of discarded attack weights.
%% We enforce: extension_cost ≤ beta (total precedent deviation ≤ β)

:- extension_cost(C), C > beta.

%% ============================================================================
%% BUDGET FACT (Needed by core/base.lp)
%% ============================================================================

budget(beta).
