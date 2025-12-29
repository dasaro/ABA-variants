%% Self-attacking argument framework
%%
%% Classical AF: ({a}, {(a,a)})
%%
%% Expected (classical):
%%   Preferred: {∅}
%%   Stable: none (empty set doesn't defeat a)
%%
%% This separates Preferred from Stable

assumption(a).

% a attacks itself
contrary(a, a).

% Weight
weight(a, 10).

% Budget - NO attack discarding (classical behavior)
budget(0).
