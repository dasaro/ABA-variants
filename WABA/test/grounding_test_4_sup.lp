%% Grounding Test 4: #sup propagation
%% Expected: Unweighted assumption propagates #sup

assumption(a1; a2).
weight(a1, 10).
% a2 has no weight, should get #sup

% Rule: c_a1 <- a2
head(r1, c_a1).
body(r1, a2).

contrary(a1, c_a1).
contrary(a2, dummy2).

% a2 (unweighted) -> #sup
% c_a1 <- a2 -> weight(c_a1) = min(#sup) = #sup
% Attack c_a1->a1 has weight #sup
% Cannot discard #sup attack with finite budget

budget(50).
