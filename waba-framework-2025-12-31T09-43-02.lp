%% Auto-generated from Simple ABA Mode

%% Assumptions
assumption(a).
assumption(b).
assumption(c).

%% Weights
weight(a, 90).
weight(c, 70).
weight(c_a, 95).
weight(c_b, 90).
weight(c_c, 85).

%% Rules
% r1: c_a <- b, c
head(r1, c_a). body(r1, b; r1, c).
% r2: c_b <- a, c
head(r2, c_b). body(r2, a; r2, c).
% r3: c_c <- a, b
head(r3, c_c). body(r3, a; r3, b).

%% Contraries
contrary(a, c_a).
contrary(b, c_b).
contrary(c, c_c).
