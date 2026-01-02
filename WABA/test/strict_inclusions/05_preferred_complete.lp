%% Framework: preferred ⊂ complete
%%
%% Setup: 2-cycle (a↔b)
%%
%% Expected:
%%   Complete: {{∅}, {a}, {b}}
%%   Preferred: {{a}, {b}} (maximal complete)
%%
%% Demonstrates: preferred ⊂ complete ({∅} is complete but not preferred)

assumption(a).
assumption(b).

contrary(a, b).  % a attacks b
contrary(b, a).  % b attacks a

weight(a, 10).
weight(b, 10).

budget(0).  % No attacks can be discarded
