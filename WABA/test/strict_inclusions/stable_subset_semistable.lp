%% Framework demonstrating: stable ⊂ semi-stable (strict)
%%
%% Expected:
%% - Stable: {a, b}
%% - Semi-stable: {a, b}, {a, c}
%%
%% Reason: {a, c} is admissible with maximal range but not stable
%%         (d is not defeated, so not stable)

assumption(a).
assumption(b).
assumption(c).
assumption(d).

%% a attacks nothing
%% b attacks c
contrary(c, b).
%% c attacks b
contrary(b, c).
%% d attacks nothing, is not attacked

weight(a, 100).
weight(b, 100).
weight(c, 100).
weight(d, 100).

#const beta = 0.
budget(beta).
