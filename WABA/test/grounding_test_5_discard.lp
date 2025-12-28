%% Grounding Test 5: Stable extension requires discarding
%% Expected: Mutual attack - must discard one to get stable extension

assumption(a1; a2).
weight(a1, 10).
weight(a2, 20).

% Mutual attacks
head(r1, c_a2).  % a1 attacks a2
body(r1, a1).

head(r2, c_a1).  % a2 attacks a1
body(r2, a2).

contrary(a1, c_a1).
contrary(a2, c_a2).

% For stable extension {a1, a2}:
%   - c_a1 (weight 20) attacks a1
%   - c_a2 (weight 10) attacks a2
%   - Must discard both: cost = max(10, 20) = 20 for MAX monoid
%
% Alternatively: {a1} or {a2} (one assumption out) - cost 0
% Optimal: cost 0 (exclude one assumption)

budget(30).
