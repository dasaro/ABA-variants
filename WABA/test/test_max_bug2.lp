% Test case where we MUST discard attacks
% a1 <-> a2 (mutual attack)
% a3 can accept both or must choose

assumption(a1).
assumption(a2).
assumption(a3).

weight(a1, 30).
weight(a2, 50).
weight(a3, 10).

% Mutual attacks via contraries
head(r1, c_a1).
body(r1, a2).

head(r2, c_a2).
body(r2, a1).

% a3 unrelated
contrary(a1, c_a1).
contrary(a2, c_a2).
contrary(a3, c_a3).

budget(100).
