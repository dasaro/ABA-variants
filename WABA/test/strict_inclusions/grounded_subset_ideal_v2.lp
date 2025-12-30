%% Framework demonstrating: grounded ⊂ ideal (strict)
%%
%% Expected:
%% - Grounded: {} (no unattacked assumptions)
%% - Ideal: {a} (maximal admissible in intersection of preferred)
%% - Preferred: {a, b}, {a, c} (both contain a)
%%
%% Intersection of preferred = {a}
%% Ideal = {a} if admissible

assumption(a).
assumption(b).
assumption(c).
assumption(d).

%% d attacks a (so a is not in grounded)
contrary(a, d).

%% b and c attack each other
contrary(b, c).
contrary(c, b).

%% a attacks d (so {a} defeats all attacks on itself)
contrary(d, a).

%% Expected:
%% - {a, b} is complete: a defends itself against d, b is unattacked by c
%% - {a, c} is complete: a defends itself against d, c is unattacked by b
%% - Preferred = {a, b}, {a, c}
%% - Intersection = {a}
%% - {a} is admissible (defends against d)
%% - Ideal = {a}
%% - Grounded = {} (a is attacked by d initially)

weight(a, 100).
weight(b, 100).
weight(c, 100).
weight(d, 100).

#const beta = 0.
budget(beta).
