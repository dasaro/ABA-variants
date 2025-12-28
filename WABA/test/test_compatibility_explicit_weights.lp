%% Test "Incompatible" Combinations with ALL Explicit Weights
%%
%% Remove the #sup propagation issue by giving EVERY assumption an explicit weight
%% This lets us see the pure semiring/monoid behavior

%% Two competing options - WITH EXPLICIT WEIGHTS
assumption(option_a). weight(option_a, 10).
assumption(option_b). weight(option_b, 5).

%% Evidence with explicit weights
assumption(evidence_a). weight(evidence_a, 40).
assumption(evidence_b). weight(evidence_b, 30).

%% Rules deriving support
%% r1: support_a <- option_a, evidence_a.
head(r1, support_a).
body(r1, option_a).
body(r1, evidence_a).

%% r2: support_b <- option_b, evidence_b.
head(r2, support_b).
body(r2, option_b).
body(r2, evidence_b).

%% Mutual attacks
contrary(option_a, support_b).
contrary(option_b, support_a).

%% Budget: moderate value
budget(50).

%% ======================================================================
%% TEST 1: TROPICAL + MAX (supposedly incompatible per compatibility theory)
%% ======================================================================
%%
%% Tropical semiring:
%% - Conjunction: + (addition)
%% - Disjunction: min
%% - Identity: #sup
%%
%% Expected derivation weights:
%% - support_a: 10 + 40 = 50 (Tropical adds weights)
%% - support_b: 5 + 30 = 35
%%
%% Attack weights:
%% - support_b attacks option_a (weight 35)
%% - support_a attacks option_b (weight 50)
%%
%% MAX monoid with UB:
%% Extension {option_a}:
%% - Discards: support_b→option_a (35)
%% - Cost: max(35) = 35
%% - Check: 35 ≤ 50 ✓ ACCEPTED
%%
%% Extension {option_b}:
%% - Discards: support_a→option_b (50)
%% - Cost: max(50) = 50
%% - Check: 50 ≤ 50 ✓ ACCEPTED
%%
%% Extension {option_a, option_b}:
%% - Discards: both attacks
%% - Cost: max(35, 50) = 50
%% - Check: 50 ≤ 50 ✓ ACCEPTED
%%
%% EXPECTED: Should find 3 stable extensions!
%% SEMANTICS: Cost minimization with additive evidence accumulation
%% MEANINGFUL? YES - this is legitimate weighted reasoning!
%%
%% Run: clingo -n 0 core/base.lp semiring/tropical.lp monoid/baseline/max.lp \
%%             filter/standard.lp semantics/stable.lp test/test_compatibility_explicit_weights.lp

%% ======================================================================
%% TEST 2: TROPICAL + SUM (supposedly incompatible)
%% ======================================================================
%%
%% Same setup, but SUM monoid:
%% Extension {option_a, option_b}:
%% - Discards: both attacks
%% - Cost: sum(35, 50) = 85
%% - Check: 85 ≤ 50? NO! REJECTED
%%
%% Extension {option_a}: cost = 35 ✓
%% Extension {option_b}: cost = 50 ✓
%%
%% EXPECTED: Should find 2 stable extensions (not the combined one)
%% SEMANTICS: Total cost budget constraint
%% MEANINGFUL? YES - this is total expenditure control!
%%
%% Run: clingo -n 0 core/base.lp semiring/tropical.lp monoid/baseline/sum.lp \
%%             filter/standard.lp semantics/stable.lp test/test_compatibility_explicit_weights.lp

%% ======================================================================
%% TEST 3: GÖDEL + MIN with LB (supposedly incompatible)
%% ======================================================================
%%
%% Gödel semiring:
%% - Conjunction: min (weakest link)
%% - Disjunction: max (strongest path)
%% - Identity: #sup
%%
%% Expected derivation weights:
%% - support_a: min(10, 40) = 10 (weakest element in chain)
%% - support_b: min(5, 30) = 5
%%
%% Attack weights:
%% - support_b attacks option_a (weight 5)
%% - support_a attacks option_b (weight 10)
%%
%% MIN monoid with LB (budget=50):
%% Extension {option_a}:
%% - Discards: support_b→option_a (5)
%% - Cost: min(5) = 5
%% - Check: 5 ≥ 50? NO! REJECTED (quality too low)
%%
%% Extension {option_b}:
%% - Discards: support_a→option_b (10)
%% - Cost: min(10) = 10
%% - Check: 10 ≥ 50? NO! REJECTED
%%
%% Extension {option_a, option_b}:
%% - Discards: both attacks
%% - Cost: min(5, 10) = 5
%% - Check: 5 ≥ 50? NO! REJECTED
%%
%% EXPECTED: Should find 0 stable extensions (budget too high)!
%%
%% Now try with budget=5:
%% Extension {option_a}: 5 ≥ 5 ✓ ACCEPTED
%% Extension {option_b}: 10 ≥ 5 ✓ ACCEPTED
%% Extension {both}: 5 ≥ 5 ✓ ACCEPTED
%%
%% SEMANTICS: Quality threshold - only accept if discarded attacks meet minimum quality
%% MEANINGFUL? YES - this is legitimate quality control!
%%
%% Run: clingo -n 0 -c beta=5 core/base.lp semiring/godel.lp monoid/baseline/min.lp \
%%             filter/standard.lp semantics/stable.lp test/test_compatibility_explicit_weights.lp

%% ======================================================================
%% HYPOTHESIS:
%% "Incompatibility" is NOT about computational well-definedness.
%% It's about whether the combination recovers classical ABA behavior
%% when budget is set appropriately with unweighted frameworks.
%%
%% All these combinations are SEMANTICALLY MEANINGFUL for weighted reasoning!
%% They just have different interpretations:
%% - Tropical+MAX: Minimize worst-case cost with additive evidence
%% - Tropical+SUM: Total cost budget with additive evidence
%% - Gödel+MIN: Quality threshold with weakest-link evidence
%% ======================================================================
