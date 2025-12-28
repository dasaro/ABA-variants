%% Test Extension Cost Computation with Arctic Semiring
%%
%% Simple scenario to verify extension_cost is computed correctly
%% with different monoids (MAX, SUM, MIN, COUNT)
%%
%% Setup: Three competing options with different accumulated rewards
%% - option_a: strong evidence (weight 100 accumulated)
%% - option_b: moderate evidence (weight 60 accumulated)
%% - option_c: weak evidence (weight 30 accumulated)
%% All options attack each other (mutually exclusive)

%% Three mutually exclusive options
assumption(option_a).
assumption(option_b).
assumption(option_c).

%% Evidence supporting each option (assumptions with weights)
assumption(evidence_a1). weight(evidence_a1, 40).
assumption(evidence_a2). weight(evidence_a2, 60).

assumption(evidence_b1). weight(evidence_b1, 60).

assumption(evidence_c1). weight(evidence_c1, 30).

%% Rules: Derive support from evidence (Arctic accumulates via +)
%% r1: support_a <- option_a, evidence_a1, evidence_a2.
head(r1, support_a).
body(r1, option_a).
body(r1, evidence_a1).
body(r1, evidence_a2).

%% r2: support_b <- option_b, evidence_b1.
head(r2, support_b).
body(r2, option_b).
body(r2, evidence_b1).

%% r3: support_c <- option_c, evidence_c1.
head(r3, support_c).
body(r3, option_c).
body(r3, evidence_c1).

%% Mutual attacks (each support attacks the other options)
contrary(option_a, support_b).
contrary(option_a, support_c).

contrary(option_b, support_a).
contrary(option_b, support_c).

contrary(option_c, support_a).
contrary(option_c, support_b).

%% Budget: High enough to allow discarding attacks
budget(200).

%% EXPECTED RESULTS with Arctic + MAX monoid:
%%
%% Derivation weights (Arctic: accumulate via +):
%% - support_a: 0 (option_a) + 40 + 60 = 100
%% - support_b: 0 (option_b) + 60 = 60
%% - support_c: 0 (option_c) + 30 = 30
%%
%% Extension {option_a}:
%% - Accepts: support_a (weight 100)
%% - Attacks on option_a from: support_b (60), support_c (30)
%% - But support_b and support_c are NOT supported (option_b and option_c are out)
%% - No attacks to discard
%% - extension_cost(0) ✓
%%
%% Extension {option_b}:
%% - Accepts: support_b (weight 60)
%% - Attacks on option_b from: support_a (100), support_c (30)
%% - But support_a and support_c are NOT supported
%% - No attacks to discard
%% - extension_cost(0) ✓
%%
%% Extension {option_a, option_b}:
%% - Accepts: support_a (100), support_b (60)
%% - support_a attacks option_b (weight 100)
%% - support_b attacks option_a (weight 60)
%% - Must discard both attacks to keep both options
%% - MAX monoid: max(100, 60) = 100
%% - extension_cost(100) ✓
%%
%% Extension {option_a, option_c}:
%% - Accepts: support_a (100), support_c (30)
%% - support_a attacks option_c (weight 100)
%% - support_c attacks option_a (weight 30)
%% - Must discard both attacks
%% - MAX monoid: max(100, 30) = 100
%% - extension_cost(100) ✓
%%
%% Extension {option_b, option_c}:
%% - Accepts: support_b (60), support_c (30)
%% - support_b attacks option_c (weight 60)
%% - support_c attacks option_b (weight 30)
%% - Must discard both attacks
%% - MAX monoid: max(60, 30) = 60
%% - extension_cost(60) ✓
%%
%% Extension {option_a, option_b, option_c}:
%% - All three supported
%% - 6 mutual attacks: support_a→b (100), support_a→c (100),
%%                     support_b→a (60), support_b→c (60),
%%                     support_c→a (30), support_c→b (30)
%% - MAX monoid: max(100, 100, 60, 60, 30, 30) = 100
%% - extension_cost(100) ✓

%% Run with MAX monoid:
%%   clingo -n 0 core/base.lp semiring/arctic.lp monoid/baseline/max.lp \
%%          filter/standard.lp semantics/stable.lp test/test_extension_cost_arctic.lp
%%
%% Run with SUM monoid:
%%   clingo -n 0 core/base.lp semiring/arctic.lp monoid/baseline/sum.lp \
%%          filter/standard.lp semantics/stable.lp test/test_extension_cost_arctic.lp
%%   Expected costs: 0, 0, 0, 160 (100+60), 130 (100+30), 90 (60+30), 380 (sum of all 6)
%%
%% Run with COUNT monoid:
%%   clingo -n 0 core/base.lp semiring/arctic.lp monoid/baseline/count.lp \
%%          filter/standard.lp semantics/stable.lp test/test_extension_cost_arctic.lp
%%   Expected costs: 0, 0, 0, 2, 2, 2, 6
