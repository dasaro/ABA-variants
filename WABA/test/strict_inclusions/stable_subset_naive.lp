%% Framework demonstrating: stable ⊂ naive (strict)
%%
%% Expected:
%% - Stable: {a, b}
%% - Naive: {a, b}, {b, d}
%%
%% Reason: {b, d} is maximal conflict-free but not stable
%%         (a is not defeated)
%%
%% This is the journal example

assumption(a).
assumption(b).
assumption(c).
assumption(d).

contrary(b, x).
contrary(c, y).
contrary(d, z).

head(r1, w). body(r1, a).
head(r2, y). body(r2, b). body(r2, w).
head(r3, x). body(r3, c).
head(r4, z). body(r4, a). body(r4, b).

weight(a, 100).
weight(b, 100).
weight(c, 100).
weight(d, 100).
weight(w, 100).
weight(x, 100).
weight(y, 100).
weight(z, 100).

#const beta = 0.
budget(beta).
