%% Framework: stable ⊂ naive
%%
%% Setup: 2-cycle (a↔b)
%%
%% Expected:
%%   Stable: {∅} (no non-empty stable in 2-cycle)
%%   Naive: {{a}, {b}} (maximal CF)
%%
%% Demonstrates: {a} and {b} are naive but not stable

assumption(a).
assumption(b).

contrary(a, b).  % a attacks b
contrary(b, a).  % b attacks a

weight(a, 100).
weight(b, 100).

budget(0).
