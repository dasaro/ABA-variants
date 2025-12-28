%% Testing Classical ABA Recovery in "Incompatible" Combinations
%%
%% Simple unweighted ABA framework:
%% - Three assumptions in circular attack pattern
%% - Classical ABA: 3 stable extensions {a}, {b}, {c}
%% - No explicit weights (use semiring defaults)

assumption(a).
assumption(b).
assumption(c).

%% Circular attacks
contrary(b, a).  % a attacks b
contrary(c, b).  % b attacks c
contrary(a, c).  % c attacks a

%% Expected with classical ABA: 3 stable extensions, no discarding
%% {a} - b is out (attacked by a), c is out (attacked by b which isn't in... wait)
%% Actually: {a} defeats b, {b} defeats c, {c} defeats a
%% Extensions: {a}, {b}, {c}
