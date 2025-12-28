%% Viterbi Semiring Simulation via Tropical + Log Transformation
%% =============================================================
%%
%% SCENARIO: Competing Medical Diagnoses with Probabilistic Evidence
%% ------------------------------------------------------------------
%% A patient has symptoms that suggest multiple possible diagnoses.
%% Each diagnosis has a probability based on symptom evidence.
%% Diagnoses are mutually exclusive - we must choose the most probable one.
%%
%% VITERBI SEMANTICS:
%% - Symptom combination probabilities multiply
%% - We want the diagnosis with MAXIMUM combined probability
%% - Equivalent to MINIMUM cost under log transformation
%%
%% LOG TRANSFORMATION:
%% - cost = round(-log(probability) × 1000)
%% - Viterbi multiplication (×) → Tropical addition (+)
%% - Viterbi maximization (max) → Tropical minimization (min)

%% ===========================
%% ASSUMPTIONS: Competing Diagnoses
%% ===========================
%% Each diagnosis represents a hypothesis about the patient's condition.
%% They are mutually exclusive (only one can be correct).

assumption(diagnosis_flu).
assumption(diagnosis_covid).
assumption(diagnosis_cold).

%% ====================================
%% WEIGHTS: Diagnosis Probabilities (Log-Transformed)
%% ====================================
%% Each diagnosis has evidence from symptom combinations.
%% Weights represent the COST (negative log-probability) of the evidence.
%%
%% FLU evidence: fever(0.90) × cough(0.85) × fatigue(0.70) = 0.5355
%%   → cost = -log(0.5355) × 1000 ≈ 625
weight(diagnosis_flu, 625).
%%
%% COVID evidence: fever(0.90) × cough(0.85) × headache(0.75) = 0.574
%%   → cost = -log(0.574) × 1000 ≈ 556
weight(diagnosis_covid, 556).
%%
%% COLD evidence: cough(0.85) × fatigue(0.70) = 0.595 ← HIGHEST PROBABILITY
%%   → cost = -log(0.595) × 1000 ≈ 520 ← LOWEST COST
weight(diagnosis_cold, 520).

%% ====================================
%% CONTRARIES: Function from Assumptions to Atoms
%% ====================================
%% Each diagnosis is attacked by a unique "rejection" atom.
%% This makes contrary/2 a total function (one contrary per assumption).

contrary(diagnosis_flu, reject_flu).
contrary(diagnosis_covid, reject_covid).
contrary(diagnosis_cold, reject_cold).

%% ====================================
%% RULES: Mutual Exclusion via Rejection Atoms
%% ====================================
%% Rejection atoms are derived when competing diagnoses are chosen.
%% This creates mutual exclusion: choosing one diagnosis rejects the others.

%% Choosing COVID or COLD rejects FLU
head(r_reject_flu_1, reject_flu).
body(r_reject_flu_1, diagnosis_covid).

head(r_reject_flu_2, reject_flu).
body(r_reject_flu_2, diagnosis_cold).

%% Choosing FLU or COLD rejects COVID
head(r_reject_covid_1, reject_covid).
body(r_reject_covid_1, diagnosis_flu).

head(r_reject_covid_2, reject_covid).
body(r_reject_covid_2, diagnosis_cold).

%% Choosing FLU or COVID rejects COLD
head(r_reject_cold_1, reject_cold).
body(r_reject_cold_1, diagnosis_flu).

head(r_reject_cold_2, reject_cold).
body(r_reject_cold_2, diagnosis_covid).

%% ====================================
%% BUDGET
%% ====================================
%% Set budget high enough to allow any diagnosis to be chosen.
budget(1000).

%% ====================================
%% EXPECTED RESULTS
%% ====================================
%%
%% DIAGNOSIS COSTS (lower = higher probability):
%% - diagnosis_cold:  520 (p≈0.595) ← VITERBI OPTIMUM
%% - diagnosis_covid: 556 (p≈0.574)
%% - diagnosis_flu:   625 (p≈0.536)
%%
%% THREE STABLE EXTENSIONS:
%%
%% Answer 1: Keep diagnosis_covid (cost 556)
%% - in(diagnosis_covid)
%% - Derived: reject_flu (556), reject_cold (556)
%% - Attacks: reject_flu → diagnosis_flu, reject_cold → diagnosis_cold
%% - extension_cost = #sup (no discards needed)
%%
%% Answer 2: Keep diagnosis_flu (cost 625)
%% - in(diagnosis_flu)
%% - Derived: reject_covid (625), reject_cold (625)
%% - Attacks: reject_covid → diagnosis_covid, reject_cold → diagnosis_cold
%% - extension_cost = #sup (no discards needed)
%%
%% Answer 3: Keep diagnosis_cold (cost 520) ← VITERBI OPTIMUM
%% - in(diagnosis_cold)
%% - Derived: reject_flu (520), reject_covid (520)
%% - Attacks: reject_flu → diagnosis_flu, reject_covid → diagnosis_covid
%% - extension_cost = #sup (no discards needed)
%%
%% INTERPRETATION:
%% - Tropical semiring propagates log-probabilities correctly
%% - Each extension chooses exactly one diagnosis (mutual exclusion)
%% - Extension with LOWEST diagnosis cost = HIGHEST probability
%% - Answer 3 (diagnosis_cold with cost 520) is the Viterbi optimum
%%
%% CONFIGURATION:
%% - Semiring: Tropical (log of probabilities, addition simulates multiplication)
%% - Monoid: MIN (minimum of discarded attack costs)
%% - Constraint: LB (lower bound) with MAXIMIZE
%% - Semantics: Stable
%%
%% COMMAND:
%% clingo -n 0 core/base.lp semiring/tropical.lp monoid/baseline/min.lp constraint/lb.lp \
%%        filter/standard.lp optimize/maximize.lp semantics/stable.lp \
%%        examples/viterbi_simulation.lp
