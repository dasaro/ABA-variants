% Simple test to demonstrate MAX minimization bug
% Three assumptions, two attack one

assumption(a1).
assumption(a2).
assumption(a3).

weight(a1, 10).
weight(a2, 20).

% a1 attacks a3, a2 attacks a3
head(r1, c_a3).
body(r1, a1).

head(r2, c_a3).
body(r2, a2).

contrary(a3, c_a3).
budget(100).
