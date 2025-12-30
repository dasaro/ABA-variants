%% Journal Paper Example from ASPforABA
%% Reference: Lehtonen, Wallner, Järvisalo 2021 (JAIR)
%%
%% Expected extension counts (with budget=0):
%% - Admissible: 7
%% - Complete: 3
%% - Stable: 2
%% - Preferred: 2
%% - Grounded: 1
%% - Ideal: 1
%%
%% Complete extensions: {a}, {a,b}, {a,c,d}
%% Stable extensions: {a,b}, {a,c,d}
%% Preferred extensions: {a,b}, {a,c,d}
%% Grounded extension: {a}
%% Ideal extension: {a}

%% Assumptions
assumption(a).
assumption(b).
assumption(c).
assumption(d).

%% Contraries
contrary(b, x).
contrary(c, y).
contrary(d, z).

%% Rules
% w <- a
head(r1, w). body(r1, a).

% y <- b, w
head(r2, y). body(r2, b). body(r2, w).

% x <- c
head(r3, x). body(r3, c).

% z <- a, b
head(r4, z). body(r4, a). body(r4, b).

%% Weights (all unweighted = default #sup)
weight(a, 100).
weight(b, 100).
weight(c, 100).
weight(d, 100).
weight(w, 100).
weight(x, 100).
weight(y, 100).
weight(z, 100).

%% Budget: 0 for classical ABA (no attack discarding)
#const beta = 0.
budget(beta).
