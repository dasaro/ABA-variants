%% Framework: admissible ⊂ conflict-free
%%
%% Setup: a→b (one-way attack)
%%
%% Expected:
%%   Conflict-free: {{∅}, {a}, {b}}
%%   Admissible: {{∅}, {a}} ({b} is CF but attacked by undefeated a)
%%
%% Demonstrates: admissible ⊂ conflict-free ({b} is CF but not admissible)

assumption(a).
assumption(b).

contrary(a, b).  % a attacks b
contrary(b, b).  % b has dummy contrary

weight(a, 10).
weight(b, 10).

budget(0).  % No attacks can be discarded
