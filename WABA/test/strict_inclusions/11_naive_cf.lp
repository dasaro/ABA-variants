%% Framework: naive ⊂ conflict-free
%%
%% Setup: a→b with isolated c
%%
%% Expected:
%%   Naive: {{a,c}} (maximal ⊆ among CF)
%%   Conflict-free: {{∅}, {a}, {c}, {a,c}}
%%
%% Demonstrates: naive ⊂ conflict-free ({a} and {c} are CF but not naive)

assumption(a).
assumption(b).
assumption(c).

contrary(a, b).  % a attacks b
contrary(b, a).  % b attacks a
contrary(c, c).  % Dummy contrary for c

weight(a, 10).
weight(b, 10).
weight(c, 10).

budget(0).  % No attacks can be discarded
