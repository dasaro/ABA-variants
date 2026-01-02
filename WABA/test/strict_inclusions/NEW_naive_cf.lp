%% Framework: naive ⊂ conflict-free
%%
%% Setup: a→b with isolated c
%%
%% Expected:
%%   Naive: {{a,c}} (maximal ⊆ among CF)
%%   Conflict-free: {{∅}, {a}, {c}, {a,c}}
%%
%% Demonstrates: {a} and {c} are CF but not naive (not maximal)

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
