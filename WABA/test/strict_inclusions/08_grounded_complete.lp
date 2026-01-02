%% Framework: grounded ⊂ complete
%%
%% Setup: 2-cycle (a↔b)
%%
%% Expected:
%%   Grounded: {∅} (minimal complete)
%%   Complete: {{∅}, {a}, {b}}
%%
%% Demonstrates: grounded ⊂ complete ({a} and {b} are complete but not grounded)

assumption(a).
assumption(b).

contrary(a, b).  % a attacks b
contrary(b, a).  % b attacks a

weight(a, 10).
weight(b, 10).

budget(0).  % No attacks can be discarded
