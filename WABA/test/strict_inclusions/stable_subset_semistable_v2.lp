%% Framework demonstrating: stable ⊂ semi-stable (strict)
%%
%% Expected:
%% - Stable: UNSATISFIABLE (no stable extensions)
%% - Semi-stable: {a}, {b} (both admissible with maximal range)
%%
%% Reason: In odd cycles, no stable extensions exist,
%%         but semi-stable extensions do

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
