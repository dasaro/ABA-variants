%% Framework: stage ⊂ conflict-free
%%
%% Setup: a→b with isolated c
%%
%% Expected:
%%   Stage: {{a,c}} (maximal range)
%%   Conflict-free: {{∅}, {a}, {c}, {a,c}}
%%
%% Demonstrates: {a} and {c} are CF but not stage (smaller range)

assumption(a).
assumption(b).
assumption(c).

contrary(a, b).  % a attacks b
contrary(b, a).  % b attacks a
contrary(c, c).  % Dummy contrary for c

weight(a, 100).
weight(b, 100).
weight(c, 100).

budget(0).
