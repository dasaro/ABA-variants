%% Framework demonstrating: admissible ⊂ conflict-free (strict)
%%
%% Expected:
%% - Admissible: {a}
%% - Conflict-free: {a}, {b}
%%
%% Reason: {b} is conflict-free but not admissible
%%         (b doesn't defend itself against attack from a)

assumption(a).
assumption(b).

%% a attacks b
contrary(b, a).

weight(a, 100).
weight(b, 100).

#const beta = 0.
budget(beta).
