%% Minimal test for ub_max with beta=0

assumption(a).
assumption(b).

contrary(b, a).  % a attacks b

weight(a, 1).
weight(b, 1).

%% Explicitly set budget to 0
#const beta = 0.
budget(beta).
