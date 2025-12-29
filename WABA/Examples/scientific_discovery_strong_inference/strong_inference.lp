%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STRONG INFERENCE / ULAM-RÉNYI - "Nature Can Lie m Times"
%%
%% STORY:
%% A scientist evaluates competing hypotheses (h1: Newtonian, h2: relativistic,
%% h3: quantum, h4: string theory) through decisive experiments. Each experiment
%% yields outcomes that reject specific hypotheses. Discarding a rejection =
%% treating experimental evidence as erroneous ("Nature lied"). We minimize
%% error count while maintaining at least one hypothesis.
%%
%% WEIGHT INTERPRETATION:
%% Weights represent evidential strength of rejection (0-100). Higher weights =
%% stronger experimental contradiction (harder to dismiss as error).
%%
%% SEMIRING: Tropical (sum/min)
%% JUSTIFICATION: Rejection evidence accumulates across multiple experiments.
%% When multiple experiments reject a hypothesis, their evidential strength
%% combines additively (cumulative disconfirmation).
%%
%% MONOID: Count
%% JUSTIFICATION: Extension cost = number of rejected experimental outcomes
%% dismissed as errors. We count how many times "Nature lied" (weight-agnostic).
%%
%% OPTIMIZATION: Minimize
%% JUSTIFICATION: Minimize number of experimental errors (epistemic parsimony).
%% Prefer interpretations requiring fewer assumptions of experimental failure.
%%
%% BUDGET β: Upper bound on experimental errors.
%% β = 2 means "Nature may lie at most 2 times" (tolerate ≤2 erroneous outcomes)
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding a rejection = dismissing experimental evidence as unreliable
%% (cost = 1 error in count). We count how many experimental outcomes we distrust.
%%
%% USAGE:
%% clingo -n 0 --opt-mode=opt -c beta=2 \
%%   WABA/core/base.lp \
%%   WABA/semiring/tropical.lp \
%%   WABA/monoid/count_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/examples/scientific_discovery_strong_inference/strong_inference.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 2.

%% ============================================================================
%% ASSUMPTIONS (Competing Hypotheses)
%% ============================================================================

assumption(h1).  % Newtonian mechanics
assumption(h2).  % Relativistic mechanics
assumption(h3).  % Quantum mechanics
assumption(h4).  % String theory

%% ============================================================================
%% WEIGHTS (Evidential Strength of Rejections)
%% ============================================================================

%% Hypothesis weights (theoretical simplicity - for Tropical accumulation)
weight(h1, 20).   % Simplest theory
weight(h2, 40).   % More complex
weight(h3, 50).   % Highly complex
weight(h4, 70).   % Most speculative

%% Experimental outcome weights (rejection evidence strength)
weight(outcome_mercury_precession, 85).   % Very strong evidence
weight(outcome_photoelectric_effect, 80). % Strong evidence
weight(outcome_gravitational_waves, 75).  % Strong evidence

%% Rejection token weights (derived from outcomes)
weight(rejects_h1_via_e1, 85).
weight(rejects_h1_via_e2, 80).
weight(rejects_h3_via_e3, 75).

%% Aggregate rejection weights
weight(rejected_h1, 90).  % Newtonian rejected by multiple experiments
weight(rejected_h3, 75).  % Quantum rejected by one experiment

%% Mixed-body derived atoms
weight(confirms_relativistic, 60).

%% ============================================================================
%% RULES (Experiments → Outcomes → Rejections)
%% ============================================================================

%% r1-r3: Experiments always occur (observational facts)
head(r1, experiment_e1).  % Mercury perihelion precession
head(r2, experiment_e2).  % Photoelectric effect
head(r3, experiment_e3).  % Gravitational wave detection

%% r4-r6: Experiments yield specific outcomes
head(r4, outcome_mercury_precession).
body(r4, experiment_e1).

head(r5, outcome_photoelectric_effect).
body(r5, experiment_e2).

head(r6, outcome_gravitational_waves).
body(r6, experiment_e3).

%% r7-r9: Outcomes generate rejection tokens (specific hypothesis + experiment)
head(r7, rejects_h1_via_e1).  % Mercury precession rejects Newtonian
body(r7, outcome_mercury_precession).

head(r8, rejects_h1_via_e2).  % Photoelectric effect rejects Newtonian
body(r8, outcome_photoelectric_effect).

head(r9, rejects_h3_via_e3).  % Gravitational waves (classical phenomenon) challenge pure quantum
body(r9, outcome_gravitational_waves).

%% r10-r11: Aggregate rejections (multiple experiments → stronger rejection)
head(r10, rejected_h1).  % Newtonian rejected by e1, e2 (Tropical sum: 85+80=165)
body(r10, rejects_h1_via_e1).
body(r10, rejects_h1_via_e2).

head(r11, rejected_h3).  % Quantum rejected by e3 (weight: 75)
body(r11, rejects_h3_via_e3).

%% r12: MIXED-BODY RULE - Relativistic hypothesis confirmed by its predictions
head(r12, confirms_relativistic).
body(r12, h2).                          % Assumption (relativistic hypothesis)
body(r12, outcome_mercury_precession).   % Derived atom (experimental outcome)

%% ============================================================================
%% CONTRARIES (Rejections Defeat Hypotheses)
%% ============================================================================

contrary(h1, rejected_h1).  % Newtonian defeated by cumulative rejection
contrary(h3, rejected_h3).  % Quantum defeated by gravitational wave evidence

%% Note: h2 (relativistic) and h4 (string theory) have no experimental rejections yet.
%% To satisfy totality, we include vacuous contraries (never derived):
contrary(h2, rejected_h2_placeholder).
contrary(h4, rejected_h4_placeholder).

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub_count.lp
%% (experimental error count ≤ β)
