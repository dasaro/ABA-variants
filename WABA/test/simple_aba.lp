%% Simple ABA framework for testing semantic inclusions
%%
%% Assumptions: a, b
%% b is attacked by a
%% Expected:
%% - Grounded: {a}
%% - Complete: {a}, {a,b}
%% - Preferred: {a,b}
%% - Stable: {a,b} (if b must be defeated)
%% - Ideal: {a}

assumption(a).
assumption(b).

%% b is contrary to a (so a attacks b)
contrary(b, a).

weight(a, 100).
weight(b, 100).

#const beta = 0.
budget(beta).
