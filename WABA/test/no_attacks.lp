%% No attacks: assumptions with no contraries
%% Expected: all semantics should return {a, b, c}

assumption(a).
assumption(b).
assumption(c).

weight(a, 100).
weight(b, 100).
weight(c, 100).

#const beta = 0.
budget(beta).
