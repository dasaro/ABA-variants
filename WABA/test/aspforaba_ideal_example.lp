%% Ideal Semantics Example from ASPforABA
%% Reference: test_ideal_and_pref() from test_simple.py
%% From Dung, Mancarella, Toni 2007 (AIJ)
%%
%% Expected behavior:
%% - Ideal extension: {b}
%% - Preferred extensions: {b,d}, {b,c}
%% - Grounded extension: empty set

%% Assumptions
assumption(a).
assumption(b).
assumption(c).
assumption(d).

%% Rules
% x <- a
head(r1, x). body(r1, a).

% y <- c
head(r2, y). body(r2, c).

% z <- d
head(r3, z). body(r3, d).

%% Contraries
contrary(a, x).
contrary(b, x).
contrary(a, b).
contrary(d, y).
contrary(c, z).

%% Weights (all unweighted)
weight(a, 100).
weight(b, 100).
weight(c, 100).
weight(d, 100).
weight(x, 100).
weight(y, 100).
weight(z, 100).

%% Budget: 0 for classical ABA
#const beta = 0.
budget(beta).
