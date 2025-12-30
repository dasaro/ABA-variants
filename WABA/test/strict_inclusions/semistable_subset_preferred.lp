%% Framework demonstrating: semi-stable ⊂ preferred (strict)
%%
%% Expected:
%% - Semi-stable: {a, b}
%% - Preferred: {a, b}, {a, c}
%%
%% Reason: {a, c} is complete (preferred) but has smaller range than {a, b}

assumption(a).
assumption(b).
assumption(c).

%% b attacks c
contrary(c, b).
%% c attacks b
contrary(b, c).

weight(a, 100).
weight(b, 100).
weight(c, 100).

#const beta = 0.
budget(beta).
