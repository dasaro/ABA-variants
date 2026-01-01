%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Large Asymmetric Ranges
%%
%% GOAL: Create semi-stable ⊂ preferred with asymmetric attack reach
%%
%% STRATEGY: Multiple groups where different preferred extensions
%%           reach (attack) different sets of peripheral arguments
%%
%% STRUCTURE:
%%   Core choice: {a1} vs {a2} (mutual exclusion)
%%
%%   Branch 1 (attacked by a1):
%%     b1 → b2 → b3 → b4 → b5 (chain)
%%
%%   Branch 2 (attacked by a2):
%%     c1 → c2 → c3 → c4 → c5 (chain)
%%
%%   Peripheral assumptions (no attacks, independent):
%%     p1, p2, p3, p4, p5 (always in complete extensions)
%%
%% With budget(0) - no discarding:
%%
%% Expected extensions:
%%   E1 = {a1, b2, b4, c1, c2, c3, c4, c5, p1, p2, p3, p4, p5}
%%     - a1 attacks b1, so b1 out
%%     - b1 out → b1→b2 inactive → b2 in
%%     - b2 attacks b3, so b3 out
%%     - b3 out → b3→b4 inactive → b4 in
%%     - b4 attacks b5, so b5 out
%%     - a2 out (defeated by a1)
%%     - a2 out → no attack on c1 → c1 in → c1 attacks c2 → c2 out
%%       Wait, this gets complicated...
%%
%% Let me simplify:
%%   Core: a1 ↔ a2 (mutual, must choose one)
%%
%%   If a1 chosen:
%%     a1 → b_group (attacks entire b group)
%%     b_group has multiple assumptions
%%
%%   If a2 chosen:
%%     a2 → c_group (attacks entire c group)
%%     c_group has multiple assumptions
%%
%% Actually, let me use a SIMPLER pattern that's known to work:
%%   Two independent subgraphs with different sizes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).  %% Allow some discarding for multiple scenarios

%% Core choice: mutual exclusion
assumption(a1).
assumption(a2).

weight(a1, 50).
weight(a2, 50).

%% a1 ↔ a2 mutual attacks
head(r_a1_a2, c_a2).
body(r_a1_a2, a1).
contrary(a2, c_a2).
weight(c_a2, 50).

head(r_a2_a1, c_a1).
body(r_a2_a1, a2).
contrary(a1, c_a1).
weight(c_a1, 50).

%% Large branch (only attacked if a1 is in):
assumption(b1).
assumption(b2).
assumption(b3).
assumption(b4).
assumption(b5).
assumption(b6).
assumption(b7).
assumption(b8).

weight(b1, 10).
weight(b2, 10).
weight(b3, 10).
weight(b4, 10).
weight(b5, 10).
weight(b6, 10).
weight(b7, 10).
weight(b8, 10).

%% a1 attacks all of b branch
head(r_a1_b1, c_b1).
body(r_a1_b1, a1).
contrary(b1, c_b1).
weight(c_b1, 10).

head(r_a1_b2, c_b2).
body(r_a1_b2, a1).
contrary(b2, c_b2).
weight(c_b2, 10).

head(r_a1_b3, c_b3).
body(r_a1_b3, a1).
contrary(b3, c_b3).
weight(c_b3, 10).

head(r_a1_b4, c_b4).
body(r_a1_b4, a1).
contrary(b4, c_b4).
weight(c_b4, 10).

head(r_a1_b5, c_b5).
body(r_a1_b5, a1).
contrary(b5, c_b5).
weight(c_b5, 10).

head(r_a1_b6, c_b6).
body(r_a1_b6, a1).
contrary(b6, c_b6).
weight(c_b6, 10).

head(r_a1_b7, c_b7).
body(r_a1_b7, a1).
contrary(b7, c_b7).
weight(c_b7, 10).

head(r_a1_b8, c_b8).
body(r_a1_b8, a1).
contrary(b8, c_b8).
weight(c_b8, 10).

%% Small branch (only attacked if a2 is in):
assumption(c1).
assumption(c2).

weight(c1, 10).
weight(c2, 10).

%% a2 attacks c branch
head(r_a2_c1, cc_c1).
body(r_a2_c1, a2).
contrary(c1, cc_c1).
weight(cc_c1, 10).

head(r_a2_c2, cc_c2).
body(r_a2_c2, a2).
contrary(c2, cc_c2).
weight(cc_c2, 10).

%% Expected:
%% E1 = {a1, c1, c2}: attacks {a2, b1, b2, b3, b4, b5, b6, b7, b8}
%%      range = {a1, a2, b1-b8, c1, c2} = 12 assumptions
%%
%% E2 = {a2, b1, b2, b3, b4, b5, b6, b7, b8}: attacks {a1, c1, c2}
%%      range = {a1, a2, b1-b8, c1, c2} = 12 assumptions
%%
%% DAMN! Still same range because all assumptions are covered!
%%
%% The issue: every assumption is either IN or ATTACKED in every extension
%%
%% To fix: need assumptions that are NEITHER in NOR attacked by some extensions
%% This requires truly isolated assumptions that violate completeness...
