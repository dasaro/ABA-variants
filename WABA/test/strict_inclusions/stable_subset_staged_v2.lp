%% Framework demonstrating: stable ⊂ staged (strict)
%%
%% Expected:
%% - Stable: UNSATISFIABLE (no stable extensions)
%% - Staged: {a}, {b}, {c} (conflict-free with maximal range)
%%
%% Odd cycle has no stable but has staged

assumption(a).
assumption(b).
assumption(c).

%% Odd cycle: a → b → c → a
contrary(b, a).
contrary(c, b).
contrary(a, c).

weight(a, 100).
weight(b, 100).
weight(c, 100).

#const beta = 0.
budget(beta).
