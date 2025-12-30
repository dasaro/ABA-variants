%% Framework demonstrating: stable ⊂ staged (strict)
%%
%% Expected:
%% - Stable: {a, b}
%% - Staged: {a, b}, {a, c}
%%
%% Reason: {a, c} is conflict-free with maximal range but not stable
%%         (d is not defeated)

assumption(a).
assumption(b).
assumption(c).
assumption(d).

contrary(c, b).
contrary(b, c).

weight(a, 100).
weight(b, 100).
weight(c, 100).
weight(d, 100).

#const beta = 0.
budget(beta).
