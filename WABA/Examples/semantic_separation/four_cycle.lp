%% 4-cycle argumentation framework
%%
%% Classical AF: ({a,b,c,d}, {(a,b), (b,c), (c,d), (d,a)})
%%
%% Expected (classical):
%%   Stable: {a,c}, {b,d}
%%   Preferred: {a,c}, {b,d} (same as stable)
%%   Complete: {∅}, {a,c}, {b,d}
%%
%% This separates Complete from Preferred/Stable

assumption(a).
assumption(b).
assumption(c).
assumption(d).

% Cycle: a → b → c → d → a
contrary(b, a).  % a attacks b
contrary(c, b).  % b attacks c
contrary(d, c).  % c attacks d
contrary(a, d).  % d attacks a

% Weights
weight(a, 10).
weight(b, 10).
weight(c, 10).
weight(d, 10).

% Budget - NO attack discarding (classical behavior)
budget(0).
