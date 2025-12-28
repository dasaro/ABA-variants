%% Grounding Test 2: Rule chain
%% Expected: a1 supports c_a2 which attacks a2

assumption(a1; a2).
weight(a1, 10).
weight(a2, 20).

% Rule: c_a2 <- a1 (a1 attacks a2)
head(r1, c_a2).
body(r1, a1).

contrary(a1, dummy1).
contrary(a2, c_a2).

% If in={a1,a2}, then c_a2 is supported and attacks a2
% To have stable extension {a1, a2}, must discard attack c_a2->a2 (cost 10 via Gödel min)
% Optimal: Discard a2, cost = 0; or keep both and discard attack, cost = 10

budget(100).
