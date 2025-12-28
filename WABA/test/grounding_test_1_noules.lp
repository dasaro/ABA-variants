%% Grounding Test 1: No rules, only assumptions with weights
%% Expected: Optimal stable extension discards nothing (cost 0)

assumption(a1; a2; a3).
weight(a1, 10).
weight(a2, 20).
weight(a3, 30).

% No attacks - stable extension should be {a1, a2, a3} with cost 0
contrary(a1, dummy1).
contrary(a2, dummy2).
contrary(a3, dummy3).

budget(100).
