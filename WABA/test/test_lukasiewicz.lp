%% Smoke test for Łukasiewicz semiring
%% Tests n-ary conjunction formula: W = max(0, sum(w_i) - (n-1)*K) where K=100
%%
%% Expected results:
%% - d1: Binary conjunction (n=2): max(0, 60+80-100) = max(0, 40) = 40
%% - d2: Ternary conjunction (n=3): max(0, 60+80+30-200) = max(0, -30) = 0
%% - d3: Insufficient support (n=2): max(0, 30+40-100) = max(0, -30) = 0
%%
%% Run with:
%%   clingo -n 0 core/base.lp semiring/lukasiewicz.lp monoid/max.lp \
%%          filter/standard.lp semantics/stable.lp test/test_lukasiewicz.lp
%%
%% Check output for:
%%   supported_with_weight(d1,40)
%%   supported_with_weight(d2,0)
%%   supported_with_weight(d3,0)

%% Assumptions (all included by default)
assumption(a1). weight(a1, 60).
assumption(a2). weight(a2, 80).
assumption(a3). weight(a3, 30).
assumption(a4). weight(a4, 40).

%% Test 1: Binary conjunction (n=2)
%% Expected: max(0, 60+80-100) = 40
head(r1, d1).
body(r1, a1).  % weight 60
body(r1, a2).  % weight 80

%% Test 2: Ternary conjunction (n=3)
%% Expected: max(0, 60+80+30-200) = max(0, -30) = 0
head(r2, d2).
body(r2, a1).  % weight 60
body(r2, a2).  % weight 80
body(r2, a3).  % weight 30

%% Test 3: Insufficient support (n=2)
%% Expected: max(0, 30+40-100) = 0
head(r3, d3).
body(r3, a3).  % weight 30
body(r3, a4).  % weight 40

%% No attacks - pure derivation test
%% We just want to verify weight propagation

budget(1000).  % High budget to allow any discarding (none needed here)
