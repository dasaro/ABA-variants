%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% META-EVIDENCE LAYERED ARGUMENTATION - Credibility Chains & Non-Monotonic Flip
%%
%% STORY:
%% A researcher evaluates claims supported by studies S1, S2. Meta-evidence
%% reveals methodological flaws undermining study reliability. Meta-meta-evidence
%% challenges the meta-source itself, creating epistemic reversal:
%% claim supported → claim rejected → claim reinstated (3-layer defeaters).
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
%%   WABA/examples/meta_evidence_layered/meta_evidence_layered.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 60.

%% ============================================================================
%% ASSUMPTIONS (Defeasible Trust Commitments)
%% ============================================================================

assumption(trust_study_s1).      % Trust Study 1 is methodologically sound
assumption(trust_study_s2).      % Trust Study 2 is methodologically sound
assumption(accept_method_m1).    % Accept underlying measurement methodology
assumption(trust_meta_source).   % Trust the meta-analysis / critique source

%% ============================================================================
%% WEIGHTS (Credibility Penalties)
%% ============================================================================

%% Assumption weights (trust value - for Gödel min)
weight(trust_study_s1, 70).      % Moderately strong initial trust
weight(trust_study_s2, 65).      % Slightly weaker initial trust
weight(accept_method_m1, 75).    % Strong methodological confidence
weight(trust_meta_source, 60).   % Moderate meta-source trust

%% Layer 1: Object-level data weights
weight(data_s1_positive, 80).    % Study 1 positive data strength
weight(data_s2_positive, 75).    % Study 2 positive data strength
weight(supports_claim, 85).      % Claim support strength

%% Layer 2: Meta-evidence weights (credibility penalties)
weight(meta_report_bias, 55).          % Meta-source reports bias (moderate severity)
weight(method_flaw_detected, 50).      % Methodological flaw severity
weight(unreliable_s1, 70).             % Study 1 unreliability severity
weight(unreliable_s2, 65).             % Study 2 unreliability severity

%% Layer 3: Meta-meta-evidence weights (meta-source critique)
weight(meta_conflict_of_interest, 55). % Meta-source conflict severity
weight(meta_unreliable, 60).           % Meta-source unreliability severity

%% ============================================================================
%% RULES (Layer 1: Object-level Evidence)
%% ============================================================================

%% r1-r2: Observational data (always holds)
head(r1, data_s1_positive).  % Study 1 collected positive data
head(r2, data_s2_positive).  % Study 2 collected positive data

%% r3: MIXED-BODY RULE - Claim support requires trusting studies + having data
head(r3, supports_claim).
body(r3, trust_study_s1).    % Assumption
body(r3, trust_study_s2).    % Assumption
body(r3, data_s1_positive).  % Derived atom

%% ============================================================================
%% RULES (Layer 2: Meta-Evidence - Undermines Studies)
%% ============================================================================

%% r4: Meta-source reports bias (derived from trust_meta_source)
head(r4, meta_report_bias).
body(r4, trust_meta_source).  % Only reports bias if we trust meta-source

%% r5: Methodological flaw detected (requires accepting methodology + observing flaw)
head(r5, method_flaw_detected).
body(r5, accept_method_m1).   % Assumption
body(r5, meta_report_bias).   % Derived (flaw only detected via meta-report)

%% r6: MIXED-BODY RULE - Study 1 unreliable if meta-source trusted AND reports bias
head(r6, unreliable_s1).
body(r6, trust_meta_source).  % Assumption
body(r6, meta_report_bias).   % Derived atom

%% r7: MIXED-BODY RULE - Study 2 unreliable if meta-source trusted AND method flaw detected
head(r7, unreliable_s2).
body(r7, trust_meta_source).  % Assumption
body(r7, method_flaw_detected). % Derived atom

%% ============================================================================
%% RULES (Layer 3: Meta-Meta-Evidence - Undermines Meta-Source)
%% ============================================================================

%% r8: Meta-source has conflicts of interest (observational fact)
head(r8, meta_conflict_of_interest).
% No body - this is observed (e.g., funding source revealed)

%% r9: Meta-source unreliable if conflicts detected
head(r9, meta_unreliable).
body(r9, meta_conflict_of_interest).

%% ============================================================================
%% CONTRARIES (Derived Defeats Only)
%% ============================================================================

contrary(trust_study_s1, unreliable_s1).        % Study 1 trust defeated by derived unreliability
contrary(trust_study_s2, unreliable_s2).        % Study 2 trust defeated by derived unreliability
contrary(trust_meta_source, meta_unreliable).   % Meta-source trust defeated by meta-meta-evidence
contrary(accept_method_m1, method_flaw_detected). % Methodology defeated by detected flaw

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub_max.lp
%% (worst credibility override ≤ β)
