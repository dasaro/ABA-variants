%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SCIENTIFIC THEORY CHOICE - Explanatory Power vs. Theoretical Complexity
%%
%% STORY:
%% A scientist must choose between competing theoretical hypotheses (Newtonian,
%% relativistic, quantum, auxiliary) to explain experimental data. Each theory,
%% combined with observational data, generates predictions. Theories conflict
%% when they make incompatible predictions (theoretical inconsistency). We
%% maximize explanatory power while bounding total theoretical complexity.
%%
%% WEIGHT INTERPRETATION:
%% Weights represent theoretical complexity cost (0-100). Higher weights =
%% more complex theory (harder to justify, higher cognitive burden).
%%
%% SEMIRING: Tropical (sum/min)
%% JUSTIFICATION: Explanatory power accumulates across phenomena. When a
%% theory explains multiple phenomena, the evidential support combines
%% additively (cumulative explanatory strength).
%%
%% MONOID: Sum
%% JUSTIFICATION: Extension cost = total theoretical complexity of discarded
%% inconsistencies. Each time we accept a theoretical conflict, we incur
%% complexity cost. Sum represents total complexity burden.
%%
%% OPTIMIZATION: Maximize (via minimizing complexity cost)
%% JUSTIFICATION: We want to maximize explanatory power. Using sum_minimization,
%% we minimize complexity cost, which is equivalent to maximizing explanatory
%% strength (simpler theories preferred, Ockham's razor).
%%
%% BUDGET β: Upper bound on total theoretical complexity.
%% β = 120 means "total complexity ≤ 120"
%%
%% DISCARDED ATTACK INTERPRETATION:
%% Overriding an inconsistency = accepting theoretical complexity (cost =
%% complexity penalty). We maintain incompatible theories by accepting the
%% complexity burden.
%%
%% USAGE:
%% clingo -n 0 --opt-mode=opt -c beta=120 \
%%   WABA/core/base.lp \
%%   WABA/semiring/tropical.lp \
%%   WABA/monoid/sum_minimization.lp \
%%   WABA/filter/standard.lp \
%%   WABA/semantics/stable.lp \
%%   WABA/examples/scientific_theory/scientific_theory.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Budget parameter (override via -c beta=N)
#const beta = 120.

%% ============================================================================
%% ASSUMPTIONS (Theoretical Hypotheses)
%% ============================================================================

assumption(assume_newtonian).         % Newtonian mechanics applies
assumption(assume_relativistic).      % Relativistic corrections needed
assumption(assume_quantum).           % Quantum effects relevant
assumption(assume_auxiliary_h1).      % Auxiliary hypothesis 1

%% ============================================================================
%% WEIGHTS (Theoretical Complexity)
%% ============================================================================

%% Theory complexity weights (0-100, higher = more complex)
weight(assume_newtonian, 30).         % Simplest theory
weight(assume_relativistic, 60).      % More complex
weight(assume_quantum, 70).           % Most complex fundamental theory
weight(assume_auxiliary_h1, 40).      % Auxiliary adds complexity

%% Inconsistency complexity weights (cost of accepting conflicts)
weight(incompatible_newtonian_quantum, 80).   % High complexity to maintain both
weight(incompatible_classical_relativistic, 65). % Moderate complexity
weight(excessive_complexity, 50).      % Too many auxiliary hypotheses

%% Prediction weights (explanatory contribution)
weight(predict_orbit_precession, 45).
weight(predict_time_dilation, 50).
weight(explain_photoelectric, 55).

%% Observational data weights
weight(observation_mercury_precession, 20).
weight(observation_gps_time_dilation, 25).
weight(observation_photoelectric_effect, 30).

%% ============================================================================
%% RULES (Theories + Observations → Predictions → Inconsistencies)
%% ============================================================================

%% r1-r3: Observational data (always holds)
head(r1, observation_mercury_precession).
head(r2, observation_gps_time_dilation).
head(r3, observation_photoelectric_effect).

%% r4: Relativistic theory + Mercury observation → predicts precession
head(r4, predict_orbit_precession).
body(r4, assume_relativistic).
body(r4, observation_mercury_precession).

%% r5: Relativistic theory + GPS observation → predicts time dilation
head(r5, predict_time_dilation).
body(r5, assume_relativistic).
body(r5, observation_gps_time_dilation).

%% r6: Quantum theory + photoelectric observation → explains effect
head(r6, explain_photoelectric).
body(r6, assume_quantum).
body(r6, observation_photoelectric_effect).

%% r7: Newtonian + Quantum theories together → incompatible (domain conflicts)
head(r7, incompatible_newtonian_quantum).
body(r7, assume_newtonian).
body(r7, assume_quantum).

%% r8: Classical (Newtonian) + Relativistic → incompatible for high velocities
head(r8, incompatible_classical_relativistic).
body(r8, assume_newtonian).
body(r8, assume_relativistic).

%% r9: Too many auxiliary hypotheses → excessive complexity
head(r9, excessive_complexity).
body(r9, assume_auxiliary_h1).
body(r9, assume_relativistic).
body(r9, assume_quantum).

%% ============================================================================
%% CONTRARIES (Theoretical Inconsistencies Defeat Hypotheses)
%% ============================================================================

contrary(assume_newtonian, incompatible_newtonian_quantum).
contrary(assume_quantum, incompatible_newtonian_quantum).
contrary(assume_newtonian, incompatible_classical_relativistic).
contrary(assume_auxiliary_h1, excessive_complexity).

%% ============================================================================
%% BUDGET CONSTRAINT
%% ============================================================================

%% Budget constraint enforced by loading constraint/ub_sum.lp
%% (total complexity ≤ β)
