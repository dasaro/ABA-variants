%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Multiple Complete Extensions WITHOUT Discarding
%%
%% GOAL: Force grounded ⊂ complete by having multiple complete but one grounded
%%
%% STRATEGY: Use zero-cost attacks so discarding is free/unnecessary
%%           Create structure where multiple complete exist even with no discarding
%%
%% STRUCTURE:
%%   - a is unattacked (always in grounded)
%%   - b and c attack each other with ZERO cost
%%   - Since attacks cost 0, not discarding them is optimal
%%   - Complete: {a,b}, {a,c} (two extensions)
%%   - Grounded: {a} (only the unattacked one)
%%
%% EXPECTED SEMANTICS (β=100):
%%   - Grounded: {a}
%%   - Complete: {a,b}, {a,c}
%%   - Preferred: {a,b}, {a,c} (both maximal)
%%   - Semi-stable: Depends on range calculation
%%
%% KEY: Using weight 0 for attacks means discarding has no benefit
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).

assumption(a).
assumption(b).
assumption(c).

%% Assumptions have non-zero weights
weight(a, 10).
weight(b, 10).
weight(c, 10).

%% Contraries have ZERO weight - discarding is pointless!
weight(c_b, 0).
weight(c_c, 0).

%% b attacks c (zero cost)
head(r_b_c, c_c).
body(r_b_c, b).
contrary(c, c_c).

%% c attacks b (zero cost)
head(r_c_b, c_b).
body(r_c_b, c).
contrary(b, c_b).

%% a is unattacked
contrary(a, a).
