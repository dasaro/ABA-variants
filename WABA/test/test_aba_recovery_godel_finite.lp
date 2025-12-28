%% Gödel + MIN + LB with Finite Weights
%%
%% Strategy: δ = 100, β = 101
%% - Any discard: MIN(100, ...) = 100
%% - LB check: 100 ≥ 101? NO → rejected
%% - No discards: extension_cost = #sup ≥ 101? YES → accepted

assumption(a).
assumption(b).
assumption(c).

weight(a, 100).
weight(b, 100).
weight(c, 100).

contrary(b, a).
contrary(c, b).

%% Expected: Extension {a, c} with no discards
