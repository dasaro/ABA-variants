%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% META-EVIDENCE LAYERED ARGUMENTATION - Credibility Chains & Non-Monotonic Flip
%%
%% STORY (ASYMMETRIC - Clear Trust in S1):
%% A claim is supported by TWO studies: S1 (rigorous, peer-reviewed, no flaws)
%% and S2 (minor methodological concerns). A meta-analysis questions S2 but
%% finds S1 impeccable. Clear decision: trust S1 (no credibility issues),
%% accept weak concerns about S2 (low penalty), claim supported.
%%
%% WEIGHT INTERPRETATION:
%% Credibility penalty (0-100). Higher = more severe methodological flaw or
%% source unreliability (harder to dismiss).
%%
%% SEMIRING: Gödel (min/max, identity=#sup)
%% JUSTIFICATION: Credibility operates via weakest-link semantics. A claim's
%% strength is limited by the least reliable component in its support chain.
%% One decisive flaw defeats the entire argument (min for conjunction).
%%
%% MONOID: Max
%% JUSTIFICATION: Extension cost = worst single credibility override. We
%% enforce a threshold on the maximum severity of any dismissed flaw
%% (maximin epistemic conservatism).
%%
%% OPTIMIZATION: Minimize
%% JUSTIFICATION: Minimize worst-case credibility penalty ignored.
%%
%% BUDGET β: Upper bound on worst single credibility override.
%% β = 60 means "can dismiss flaws with severity ≤60, but not worse."
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding a credibility flaw = accepting evidence despite methodological
%% concerns (cost = flaw severity). We bound the worst single override.
%%
%% USAGE:
%% clingo -n 0 --opt-mode=opt -c beta=60 \
%%   WABA/core/base.lp \
%%   WABA/semiring/godel.lp \
%%   WABA/monoid/max_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/constraint/ub_max.lp \
%%   WABA/examples/meta_evidence_layered/meta_evidence_layered.lp
%%
%% EXPECTED: Extension {trust_study_s1, trust_study_s2}
%% (Trust both studies, accept minor concern about S2, claim supported)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 60.

%% Budget constraint (requires constraint/ub_max.lp to be loaded)
budget(beta).

%% ============================================================================
%% ASSUMPTIONS (Defeasible Trust Commitments)
%% ============================================================================

assumption(trust_study_s1).      % Trust Study 1 (rigorous, peer-reviewed, no flaws)
assumption(trust_study_s2).      % Trust Study 2 (minor methodological concerns)

%% ============================================================================
%% WEIGHTS (Credibility Penalties)
%% ============================================================================

%% Assumption weights - ASYMMETRIC (S1 excellent, S2 has minor issue)
weight(trust_study_s1, 95).      % Excellent study - no credibility issues
weight(trust_study_s2, 85).      % Good study - minor concerns

%% Object-level data weights
weight(data_s1_positive, 95).    % Study 1 strong positive data
weight(data_s2_positive, 85).    % Study 2 good positive data
weight(supports_claim, 90).      % Strong claim support

%% Minor methodological concern about S2 (low severity - easily accepted)
weight(minor_method_concern_s2, 30).  % Low severity: minor issue in S2

%% ============================================================================
%% RULES (Layer 1: Object-level Evidence)
%% ============================================================================

%% r1-r2: Observational data (always holds)
head(r1, data_s1_positive).  % Study 1 collected positive data
head(r2, data_s2_positive).  % Study 2 collected positive data

%% r3: Claim support requires trusting both studies + having data
head(r3, supports_claim).
body(r3, trust_study_s1).    % S1 trusted (no credibility issues)
body(r3, trust_study_s2).    % S2 trusted (minor concern accepted)
body(r3, data_s1_positive).  % S1 data available
body(r3, data_s2_positive).  % S2 data available

%% r4: Minor methodological concern about S2 (only issue)
head(r4, minor_method_concern_s2).
% No body - this is the single finding: S2 has minor methodology issue

%% Simplified: S1 is impeccable (no concerns), S2 has minor issue

%% ============================================================================
%% CONTRARIES (Derived Defeats Only)
%% ============================================================================

% Only S2 has minor concern (low severity, easily accepted)
contrary(trust_study_s2, minor_method_concern_s2).
% S1 unattacked - impeccable study

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub_max.lp
%% (worst credibility override ≤ β)
