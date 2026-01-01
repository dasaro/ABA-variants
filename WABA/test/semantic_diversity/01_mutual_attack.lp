%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Mutual Attack with Equal Weights
%%
%% GOAL: Force multiple complete extensions within same scenario
%%
%% STRUCTURE:
%%   a attacks b (weight 10)
%%   b attacks a (weight 10)
%%
%% EXPECTED SEMANTICS (β=100, no discarding needed):
%%   - Complete: {a}, {b} (two extensions - mutual exclusion)
%%   - Preferred: {a}, {b} (both maximal)
%%   - Semi-stable: {a}, {b} (equal range)
%%   - Grounded: ∅ (no unattacked assumptions, minimal is empty)
%%   - Stable: ∅ (neither {a} nor {b} defeats all out-arguments)
%%
%% KEY DISTINCTION: Grounded ⊂ Complete (strict!)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).

%% Two assumptions
assumption(a).
assumption(b).

%% Weights
weight(a, 10).
weight(b, 10).

%% Mutual attacks (direct)
contrary(a, b).
contrary(b, a).
