%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SALLY CLARK META-EVIDENCE - Legal Reasoning & Statistical Fallacies
%%
%% STORY:
%% Legal case with statistical evidence (1 in 73 million probability). Prosecution
%% argues guilt based on this statistic. Meta-evidence reveals critical flaws:
%% independence assumption violated (genetic/environmental factors), prosecutor's
%% fallacy (P(evidence|innocent) ≠ P(innocent|evidence)), unreliable expert
%% testimony. We minimize total severity of ignored methodological critiques.
%%
%% WEIGHT INTERPRETATION:
%% Severity of statistical/logical fallacy (0-100). Higher = more egregious
%% methodological error (harder to justify ignoring).
%%
%% SEMIRING: Tropical (sum/min, identity=#sup)
%% JUSTIFICATION: Statistical critiques accumulate. Multiple independent flaws
%% (independence violation + prosecutor's fallacy + unreliable expert) compound
%% to undermine evidence. Tropical sum captures cumulative methodological failure.
%%
%% MONOID: Sum
%% JUSTIFICATION: Extension cost = total severity of ignored critiques. Each
%% dismissed fallacy contributes its severity to the total epistemic burden.
%%
%% OPTIMIZATION: Minimize
%% JUSTIFICATION: Minimize total severity of ignored methodological critiques
%% (evidential conservatism in legal reasoning).
%%
%% BUDGET β: Upper bound on total ignored critique severity.
%% β = 150 means "can dismiss critiques totaling ≤150 severity units."
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding a methodological critique = accepting evidence despite logical
%% fallacy (cost = fallacy severity). We sum how much critique severity we
%% chose to disregard.
%%
%% USAGE:
%% clingo -n 0 --opt-mode=opt -c beta=150 \
%%   WABA/core/base.lp \
%%   WABA/semiring/tropical.lp \
%%   WABA/monoid/sum_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/examples/sally_clark_meta_evidence/sally_clark_meta_evidence.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 150.

%% ============================================================================
%% ASSUMPTIONS (Defeasible Evidential Commitments)
%% ============================================================================

assumption(accept_statistical_evidence).  % Accept 1 in 73 million statistic
assumption(assume_independence).          % Assume infant deaths are independent
assumption(trust_expert_witness).         % Trust statistical expert testimony
assumption(accept_prosecution_logic).     % Accept prosecution's probabilistic reasoning

%% ============================================================================
%% WEIGHTS (Fallacy Severity)
%% ============================================================================

%% Assumption weights (evidential strength - for Tropical accumulation)
weight(accept_statistical_evidence, 80). % Strong statistical evidence if valid
weight(assume_independence, 70).         % Critical independence assumption
weight(trust_expert_witness, 65).        % Expert testimony authority
weight(accept_prosecution_logic, 75).    % Prosecution reasoning strength

%% Object-level evidence weights
weight(statistical_testimony, 85).       % Expert testimony strength
weight(guilty, 90).                      % Conviction conclusion weight
weight(acquit, 95).                      % Acquittal conclusion weight

%% Supporting observational facts
weight(genetic_correlation, 60).         % Genetic factors observed
weight(environmental_factors, 55).       % Environmental factors present

%% Meta-evidence weights (critique severity)
weight(independence_violated, 80).       % Independence violation severity (major flaw)
weight(prosecutor_fallacy_detected, 85). % Prosecutor's fallacy severity (critical flaw)
weight(ecological_fallacy, 70).          % Ecological fallacy severity
weight(expert_unreliable, 75).           % Expert unreliability severity
weight(evidence_invalid, 95).            % Overall invalidity conclusion

%% ============================================================================
%% RULES (Object-Level Evidence & Verdict)
%% ============================================================================

%% r1: Statistical testimony provided (observational fact)
head(r1, statistical_testimony).
% No body - expert testimony is given

%% r2: MIXED-BODY RULE - Conviction requires accepting evidence + having testimony
head(r2, guilty).
body(r2, accept_statistical_evidence). % Assumption
body(r2, statistical_testimony).       % Derived atom

%% r3: Acquittal follows from evidence invalidity
head(r3, acquit).
body(r3, evidence_invalid).

%% ============================================================================
%% RULES (Meta-Evidence: Observational Facts Revealing Flaws)
%% ============================================================================

%% r4-r5: Observational facts (genetic and environmental correlations)
head(r4, genetic_correlation).
% No body - genetic factors discovered (e.g., SIDS risk genes)

head(r5, environmental_factors).
% No body - environmental factors identified (e.g., family history, conditions)

%% ============================================================================
%% RULES (Meta-Evidence: Critique Derivations)
%% ============================================================================

%% r6: MIXED-BODY RULE - Independence violated if genetic + environmental factors present
head(r6, independence_violated).
body(r6, genetic_correlation).    % Derived
body(r6, environmental_factors).  % Derived

%% r7: Prosecutor's fallacy detected (requires accepting prosecution logic + having evidence)
head(r7, prosecutor_fallacy_detected).
body(r7, accept_prosecution_logic). % Assumption
body(r7, statistical_testimony).    % Derived

%% r8: Ecological fallacy (applying population stats to individual case)
head(r8, ecological_fallacy).
body(r8, accept_statistical_evidence). % Assumption
body(r8, statistical_testimony).       % Derived

%% r9: Expert unreliable if testimony present and prosecution logic accepted
head(r9, expert_unreliable).
body(r9, statistical_testimony).       % Derived
body(r9, prosecutor_fallacy_detected). % Derived

%% r10: MIXED-BODY RULE - Evidence invalid if multiple critiques combine
%%      (Tropical accumulation: independence_violated + prosecutor_fallacy)
head(r10, evidence_invalid).
body(r10, independence_violated).      % Derived (weight 80)
body(r10, prosecutor_fallacy_detected). % Derived (weight 85)
% Tropical sum: 80 + 85 = 165 (cumulative critique strength)

%% ============================================================================
%% CONTRARIES (Derived Defeats Only)
%% ============================================================================

contrary(accept_statistical_evidence, evidence_invalid).     % Evidence defeated by cumulative critiques
contrary(assume_independence, independence_violated).        % Independence defeated by genetic/environmental
contrary(trust_expert_witness, expert_unreliable).          % Expert trust defeated by unreliability
contrary(accept_prosecution_logic, prosecutor_fallacy_detected). % Prosecution reasoning defeated by fallacy

%% ============================================================================
%% BUDGET CONSTRAINT (Total Ignored Critique Severity ≤ β)
%% ============================================================================

%% The sum_minimization.lp monoid defines extension_cost(C) = sum of discarded attack weights.
%% We enforce: extension_cost ≤ beta (total ignored critique severity ≤ β)

:- extension_cost(C), C > beta.

%% ============================================================================
%% BUDGET FACT
%% ============================================================================

budget(beta).
