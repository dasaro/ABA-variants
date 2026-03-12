%% Journal paper reference case from ASPforABA comparison work.
%% Expected classical results with no attack discarding:
%% - admissible: 7
%% - complete: 3
%% - stable: 2
%% - preferred: 2
%% - grounded: 1

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
