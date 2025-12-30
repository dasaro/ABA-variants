%% Even cycle: a attacks b, b attacks a
%% Expected:
%% - Grounded: {} (empty - no unattacked assumptions)
%% - Complete: {}, {a}, {b}
%% - Preferred: {a}, {b}
%% - Stable: {a}, {b}
%% - Ideal: {}

assumption(a).
assumption(b).

contrary(a, b).
contrary(b, a).

weight(a, 100).
weight(b, 100).

#const beta = 0.
budget(beta).
