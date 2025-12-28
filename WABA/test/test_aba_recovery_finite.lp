%% Testing ABA Recovery with FINITE Default Weights
%%
%% Instead of relying on #sup, can we use finite default weights
%% to prevent discarding and recover classical ABA?
%%
%% Strategy for each combination:
%% 1. Tropical + MAX + UB: δ = 1000, β = 999
%%    → Any discard gives MAX(1000) = 1000 > 999, rejected
%%
%% 2. Tropical + SUM + UB: δ = 1000, β = 999
%%    → Any discard gives SUM(1000) = 1000 > 999, rejected
%%
%% 3. Gödel + MIN + LB: δ = 100, β = 101
%%    → Any discard gives MIN(100) = 100 < 101, rejected (LB)
%%    → No discards: extension_cost = #sup ≥ 101, accepted

assumption(a).
assumption(b).
assumption(c).

%% Give ALL assumptions explicit weight (simulating modified defaults)
weight(a, 1000).
weight(b, 1000).
weight(c, 1000).

contrary(b, a).
contrary(c, b).

%% TROPICAL TESTS (δ=1000, β=999):
%% Derivation weights:
%% - a: 1000
%% - b: 1000
%% - c: 1000
%%
%% Extension {a, c}:
%% - No attacks to discard (b is out)
%% - extension_cost = 0 (or #sup)
%% - Check: 0 ≤ 999 ✓
%%
%% Extension {a, b, c} (hypothetically):
%% - Must discard: a→b (1000), b→c (1000)
%% - MAX: 1000, SUM: 2000
%% - Check MAX: 1000 > 999 ✗
%% - Check SUM: 2000 > 999 ✗
%%
%% Expected: Only {a, c}, no discarding ✓

%% For Gödel test, use weight=100 and budget=101 (test separately)
