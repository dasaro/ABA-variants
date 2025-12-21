%% Test Arctic Semiring: (+, max) for reward accumulation / longest path
%%
%% Expected behavior:
%% - Conjunction (AND): + (accumulate rewards)
%% - Disjunction (OR): max (strongest alternative)
%%
%% Test scenario: Academic research impact scoring
%% - Citations/awards have reward values
%% - Research impact = sum of all supporting evidence
%% - Multiple evidence chains → choose strongest total reward
%%
%% Expected results:
%% - impact_a: 10 + 20 + 30 = 60 (sum of all citations)
%% - impact_b: max(40, 15+25) = max(40, 40) = 40 (two paths, both equal)
%%
%% Run with:
%%   clingo -n 0 core/base.lp semiring/arctic.lp monoid/max.lp \
%%          filter/standard.lp semantics/stable.lp test/test_arctic.lp
%%
%% Check output for:
%%   supported_with_weight(impact_a,60)
%%   supported_with_weight(impact_b,40)

%% Assumptions (all included by default)
assumption(cite1). weight(cite1, 10).
assumption(cite2). weight(cite2, 20).
assumption(cite3). weight(cite3, 30).
assumption(award1). weight(award1, 40).
assumption(cite4). weight(cite4, 15).
assumption(cite5). weight(cite5, 25).

%% Test 1: Conjunction as + (accumulate rewards)
%% Body has weights 10, 20, 30
%% Expected: 10 + 20 + 30 = 60
%% r1: impact_a <- cite1, cite2, cite3.
head(r1, impact_a).
body(r1, cite1).  % reward 10
body(r1, cite2).  % reward 20
body(r1, cite3).  % reward 30

%% Test 2: Disjunction as max (strongest alternative)
%% Two rules deriving impact_b:
%%   r2a: award1 alone = 40
%%   r2b: cite4 + cite5 = 15 + 25 = 40
%% Expected: max(40, 40) = 40
%% r2a: impact_b <- award1.
head(r2a, impact_b).
body(r2a, award1).  % reward 40

%% r2b: impact_b <- cite4, cite5.
head(r2b, impact_b).
body(r2b, cite4).  % reward 15
body(r2b, cite5).  % reward 25

%% No attacks - pure derivation test
budget(0).

%% EXPECTED INTERPRETATION:
%% - Arctic semiring accumulates rewards (dual of Tropical cost minimization)
%% - impact_a: Strong cumulative evidence (60 total)
%% - impact_b: Two equally strong paths (single major award OR two moderate citations)
