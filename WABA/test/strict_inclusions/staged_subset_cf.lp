%% Framework demonstrating: staged ⊂ conflict-free (strict)
%%
%% Expected:
%% - Staged: {a, b}
%% - Conflict-free: {a}, {b}, {a, b}
%%
%% Reason: {a} and {b} are conflict-free but not range-maximal
%%         (they have smaller range than {a, b})

assumption(a).
assumption(b).

%% No attacks - all conflict-free sets valid
%% But only {a,b} has maximal range

weight(a, 100).
weight(b, 100).

#const beta = 0.
budget(beta).
