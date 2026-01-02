%% Framework: grounded ⊂ complete
%%
%% Setup: 2-cycle (a↔b)
%%
%% Expected:
%%   Grounded: {∅} (minimal complete)
%%   Complete: {{∅}, {a}, {b}}
%%
%% Demonstrates: {a} and {b} are complete but not grounded

assumption(a).
assumption(b).

contrary(a, b).  % a attacks b
contrary(b, a).  % b attacks a

weight(a, 100).
weight(b, 100).

budget(0).
