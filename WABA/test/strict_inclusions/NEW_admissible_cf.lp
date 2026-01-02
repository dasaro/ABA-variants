%% Framework: admissible ⊂ conflict-free
%%
%% Setup: a→b (one-way attack)
%%
%% Expected:
%%   Conflict-free: {{∅}, {a}, {b}}
%%   Admissible: {{∅}, {a}}
%%
%% Demonstrates: {b} is CF but not admissible (attacked by undefeated a)

assumption(a).
assumption(b).

contrary(a, b).  % a attacks b
contrary(b, a).  % b attacks a (but never triggered since b defeated)

weight(a, 100).
weight(b, 100).

budget(0).
