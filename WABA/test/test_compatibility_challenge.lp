%% Test "Incompatible" Semiring/Monoid Combinations
%%
%% Challenge: Do supposedly incompatible combinations actually fail,
%% or do they just have different (but meaningful) semantics?
%%
%% Simple scenario: Two options with evidence, mutual attacks
%%
%% Tests:
%% 1. Tropical + MAX (supposedly incompatible - different default weights)
%% 2. Tropical + SUM (supposedly incompatible)
%% 3. Gödel + MIN (supposedly incompatible)

%% Two competing options
assumption(option_a).
assumption(option_b).

%% Evidence with explicit weights
assumption(evidence_a). weight(evidence_a, 50).
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

%% Budget: moderate value to test constraint behavior
budget(50).

%% TROPICAL + MAX (supposedly incompatible):
%%
%% Tropical semiring:
%% - Default weight: 0 (for unweighted assumptions)
%% - Conjunction: + (addition)
%% - Disjunction: min
%% - Identity: #sup
%%
%% Expected derivation weights:
%% - support_a: 0 (option_a default) + 50 (evidence_a) = 50
%% - support_b: 0 (option_b default) + 30 (evidence_b) = 30
%%
%% Attack weights:
%% - support_b attacks option_a (weight 30)
%% - support_a attacks option_b (weight 50)
%%
%% Extension {option_a}:
%% - Discards attack from support_b (weight 30)
%% - MAX cost: 30
%% - Budget check: 30 ≤ 50 ✓
%% - RESULT: Should be accepted!
%%
%% Extension {option_b}:
%% - Discards attack from support_a (weight 50)
%% - MAX cost: 50
%% - Budget check: 50 ≤ 50 ✓
%% - RESULT: Should be accepted!
%%
%% Extension {option_a, option_b}:
%% - Discards both attacks
%% - MAX cost: max(30, 50) = 50
%% - Budget check: 50 ≤ 50 ✓
%% - RESULT: Should be accepted!
%%
%% EXPECTED: All three extensions should be found!
%% This combination IS semantically meaningful!

%% Run tests:
%%   clingo -n 0 core/base.lp semiring/tropical.lp monoid/baseline/max.lp \
%%          filter/standard.lp semantics/stable.lp test/test_compatibility_challenge.lp
%%
%%   clingo -n 0 core/base.lp semiring/tropical.lp monoid/baseline/sum.lp \
%%          filter/standard.lp semantics/stable.lp test/test_compatibility_challenge.lp
%%
%%   clingo -n 0 core/base.lp semiring/godel.lp monoid/baseline/min.lp \
%%          filter/standard.lp semantics/stable.lp test/test_compatibility_challenge.lp

%% PHILOSOPHICAL QUESTION:
%% What does "incompatible" actually mean?
%% - Computationally undefined? (crashes, no answer sets)
%% - Semantically meaningless? (arbitrary/nonsensical results)
%% - Doesn't recover classical ABA? (specific theoretical property)
%%
%% Hypothesis: "Incompatibility" is about ABA-recovery, not about
%% whether the combination is useful for weighted reasoning!
