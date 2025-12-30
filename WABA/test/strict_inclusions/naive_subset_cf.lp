%% Framework demonstrating: naive ⊂ conflict-free (strict)
%%
%% Expected:
%% - Naive: {a, b}
%% - Conflict-free: {a}, {b}, {a, b}
%%
%% Reason: {a} and {b} are conflict-free but not maximal

assumption(a).
assumption(b).

weight(a, 100).
weight(b, 100).

#const beta = 0.
budget(beta).
