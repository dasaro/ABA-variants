%% Framework: stage ⊂ conflict-free
%%
%% Setup: a→b with isolated c
%%
%% Expected:
%%   Stage: {{a,c}} (maximal range among CF)
%%   Conflict-free: {{∅}, {a}, {c}, {a,c}}
%%
%% Demonstrates: stage ⊂ conflict-free ({a} and {c} are CF but not stage)

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
