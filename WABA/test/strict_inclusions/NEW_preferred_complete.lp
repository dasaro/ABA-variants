%% Framework: preferred ⊂ complete
%%
%% Setup: 2-cycle (a↔b)
%%
%% Expected:
%%   Complete: {{∅}, {a}, {b}}
%%   Preferred: {{a}, {b}} (maximal complete)
%%
%% Demonstrates: {∅} is complete but not preferred

assumption(a).
assumption(b).

contrary(a, b).  % a attacks b
contrary(b, a).  % b attacks a

weight(a, 100).
weight(b, 100).

budget(0).
