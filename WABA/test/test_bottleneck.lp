%% Smoke test for Bottleneck-cost semiring
%% Tests:
%% - Conjunction (⊗): max (body weight = max of body weights, bottleneck)
%% - Disjunction (⊕): min (choose cheapest derivation)
%%
%% Expected results:
%% - d1: max(10, 20, 30) = 30 (bottleneck is worst premise)
%% - d2: min(40, 25) = 25 (choose cheaper of two derivations)
%%   - Via r2a: max(40) = 40
%%   - Via r2b: max(15, 25) = 25 → choose this one
%%
%% Run with:
%%   clingo -n 0 core/base.lp semiring/bottleneck_cost.lp monoid/min.lp \
%%          filter/standard.lp optimize/maximize.lp semantics/stable.lp test/test_bottleneck.lp
%%
%% Check output for:
%%   supported_with_weight(d1,30)
%%   supported_with_weight(d2,25)

%% Assumptions (all included by default)
assumption(a1). weight(a1, 10).
assumption(a2). weight(a2, 20).
assumption(a3). weight(a3, 30).
assumption(a4). weight(a4, 40).
assumption(a5). weight(a5, 15).
assumption(a6). weight(a6, 25).

%% Test 1: Conjunction as max (bottleneck)
%% Body has weights 10, 20, 30
%% Expected: max(10, 20, 30) = 30
head(r1, d1).
body(r1, a1).  % weight 10
body(r1, a2).  % weight 20
body(r1, a3).  % weight 30

%% Test 2: Disjunction as min (choose cheapest derivation)
%% Two rules deriving d2:
%%   r2a: max(40) = 40
%%   r2b: max(15, 25) = 25
%% Expected: min(40, 25) = 25
head(r2a, d2).
body(r2a, a4).  % weight 40

head(r2b, d2).
body(r2b, a5).  % weight 15
body(r2b, a6).  % weight 25

%% No attacks - pure derivation test
budget(0).  % Strict budget for MIN+LB (quality threshold)
