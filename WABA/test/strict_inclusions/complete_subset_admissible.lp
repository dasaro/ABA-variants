%% Framework demonstrating: complete ⊂ admissible (strict)
%%
%% Expected:
%% - Complete: {a}, {a, b}, {a, c, d}
%% - Admissible: {a}, {a, b}, {a, c, d}, {a, c}, {c, d}, {c}
%%
%% Reason: {a, c}, {c, d}, {c} are admissible but not complete
%%         (they don't contain all assumptions they defend)
%%
%% This is the ASPforABA journal example

assumption(a).
assumption(b).
assumption(c).
assumption(d).

contrary(b, x).
contrary(c, y).
contrary(d, z).

% w <- a
head(r1, w). body(r1, a).

% y <- b, w
head(r2, y). body(r2, b). body(r2, w).

% x <- c
head(r3, x). body(r3, c).

% z <- a, b
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
