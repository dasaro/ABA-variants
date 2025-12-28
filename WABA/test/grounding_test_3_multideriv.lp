%% Grounding Test 3: Multiple derivations for same head
%% Expected: c_a3 can be derived via two different rules with different weights

assumption(a1; a2; a3).
weight(a1, 10).
weight(a2, 20).

% Two rules deriving c_a3
head(r1, c_a3).  % c_a3 <- a1 (weight 10)
body(r1, a1).

head(r2, c_a3).  % c_a3 <- a2 (weight 20)
body(r2, a2).

contrary(a1, dummy1).
contrary(a2, dummy2).
contrary(a3, c_a3).

% Gödel: max(10, 20) = 20, so c_a3 has weight 20
% To discard c_a3->a3 costs 20

budget(100).
