%% Framework: stable ⊂ naive
%%
%% Setup: 2-cycle (a↔b)
%%
%% Expected:
%%   Stable: {∅}
%%   Naive: {{a}, {b}} (maximal CF = preferred in this case)
%%
%% Demonstrates: stable ⊂ naive ({a} and {b} are naive but not stable)

assumption(a).
assumption(b).

contrary(a, b).  % a attacks b
contrary(b, a).  % b attacks a

weight(a, 10).
weight(b, 10).

budget(0).  % No attacks can be discarded
