%% Framework demonstrating: semi-stable ⊂ preferred (strict)
%%
%% This uses a non-flat framework where complete ≠ range-maximal
%%
%% Expected:
%% - Semi-stable: range-maximal admissible
%% - Preferred: maximal complete (may not be range-maximal)
%%
%% Simple case: framework where {} is complete but not range-maximal

assumption(a).
assumption(b).

%% a and b attack each other
contrary(a, b).
contrary(b, a).

%% Expected:
%% - Complete/Preferred: {}, {a}, {b}
%% - Semi-stable: {a}, {b} (maximal range)
%% - So preferred has {} which is not semi-stable

weight(a, 100).
weight(b, 100).

#const beta = 0.
budget(beta).
