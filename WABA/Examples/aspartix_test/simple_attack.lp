%% Simple test framework for comparing WABA semantics with ASPARTIX
%%
%% Structure: a attacks b, c is independent
%%
%% Expected (classical ABA / AAF):
%%   Stable: {a,c}
%%   Admissible: {}, {a}, {c}, {a,c}
%%   Complete: {a,c}
%%   Grounded: {a,c}
%%   Preferred: {a,c}

assumption(a).
assumption(b).
assumption(c).

% a attacks b
contrary(b, a).

% Weights (all equal for plain ABA behavior)
weight(a, 1).
weight(b, 1).
weight(c, 1).

% Budget definition for constraint files
% Use beta=0 for plain ABA (no attack discarding)
#const beta = 0.
budget(beta).
