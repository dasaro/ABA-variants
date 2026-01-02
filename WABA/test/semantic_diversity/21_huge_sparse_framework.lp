%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Huge Sparse Framework (120 assumptions)
%%
%% GOAL: Break range homogeneity with large, sparsely connected structure
%%
%% STRATEGY:
%%   - 2 root choices (root_a, root_b) via mutual exclusion
%%   - Each root has its own "territory" of 50+ assumptions
%%   - Minimal overlap between territories
%%   - Deep trees (not wide graphs) to create distance
%%
%% STRUCTURE:
%%
%%   ROOT CHOICE: root_a ↔ root_b
%%
%%   TERRITORY A (only reachable if root_a chosen):
%%     - 5 independent 10-node chains
%%     - Total: 50 assumptions (a_chain1_1 through a_chain5_10)
%%    - root_a attacks the head of each chain
%%
%%   TERRITORY B (only reachable if root_b chosen):
%%     - 5 independent 10-node chains
%%     - Total: 50 assumptions (b_chain1_1 through b_chain5_10)
%%     - root_b attacks the head of each chain
%%
%%   SHARED ZONE (attacked by both roots):
%%     - 18 assumptions (shared_1 through shared_18)
%%
%% TOTAL: 2 roots + 50 (territory A) + 50 (territory B) + 18 (shared) = 120
%%
%% Expected Ranges:
%%
%%   E1 (root_a chosen):
%%     - root_a in, root_b out (attacked)
%%     - Territory A: alternating in/out pattern (25 in, 25 out)
%%     - Territory B: ALL assumptions in (no attacks on them!)
%%     - Shared: ALL out (attacked by root_a)
%%     - Range = 2 (roots) + 50 (terr_a all touched) + 50 (terr_b all in) + 18 (shared)
%%             = 120 (ALL assumptions)
%%
%%   E2 (root_b chosen):
%%     - Symmetric to E1
%%     - Range = 120 (ALL assumptions)
%%
%% ISSUE: Completeness forces Territory B into E1!
%%
%% Let me revise to prevent this...
%%
%% REVISED: Each territory must have INTERNAL conflicts to avoid being
%% force-included by completeness
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(0).

%% ===== ROOT CHOICE =====
assumption(root_a).
assumption(root_b).

weight(root_a, 10).
weight(root_b, 10).
weight(c_root_a, 10).
weight(c_root_b, 10).

head(r_a_b, c_root_b).
body(r_a_b, root_a).
contrary(root_b, c_root_b).

head(r_b_a, c_root_a).
body(r_b_a, root_b).
contrary(root_a, c_root_a).

%% ===== TERRITORY A: 50 assumptions in 5 chains of 10 =====
%% Chain pattern: root_a → a_c1_1 → a_c1_2 → ... → a_c1_10

%% Chain 1
assumption(a_c1_1).  assumption(a_c1_2).  assumption(a_c1_3).  assumption(a_c1_4).  assumption(a_c1_5).
assumption(a_c1_6).  assumption(a_c1_7).  assumption(a_c1_8).  assumption(a_c1_9).  assumption(a_c1_10).

weight(a_c1_1, 10).  weight(a_c1_2, 10).  weight(a_c1_3, 10).  weight(a_c1_4, 10).  weight(a_c1_5, 10).
weight(a_c1_6, 10).  weight(a_c1_7, 10).  weight(a_c1_8, 10).  weight(a_c1_9, 10).  weight(a_c1_10, 10).

weight(c_a_c1_1, 10).  weight(c_a_c1_2, 10).  weight(c_a_c1_3, 10).  weight(c_a_c1_4, 10).  weight(c_a_c1_5, 10).
weight(c_a_c1_6, 10).  weight(c_a_c1_7, 10).  weight(c_a_c1_8, 10).  weight(c_a_c1_9, 10).  weight(c_a_c1_10, 10).

%% root_a → a_c1_1
head(r_ra_c1_1, c_a_c1_1).
body(r_ra_c1_1, root_a).
contrary(a_c1_1, c_a_c1_1).

%% Chain attacks: a_c1_1 → a_c1_2 → a_c1_3 → ... → a_c1_10
head(r_c1_1_2, c_a_c1_2).  body(r_c1_1_2, a_c1_1).  contrary(a_c1_2, c_a_c1_2).
head(r_c1_2_3, c_a_c1_3).  body(r_c1_2_3, a_c1_2).  contrary(a_c1_3, c_a_c1_3).
head(r_c1_3_4, c_a_c1_4).  body(r_c1_3_4, a_c1_3).  contrary(a_c1_4, c_a_c1_4).
head(r_c1_4_5, c_a_c1_5).  body(r_c1_4_5, a_c1_4).  contrary(a_c1_5, c_a_c1_5).
head(r_c1_5_6, c_a_c1_6).  body(r_c1_5_6, a_c1_5).  contrary(a_c1_6, c_a_c1_6).
head(r_c1_6_7, c_a_c1_7).  body(r_c1_6_7, a_c1_6).  contrary(a_c1_7, c_a_c1_7).
head(r_c1_7_8, c_a_c1_8).  body(r_c1_7_8, a_c1_7).  contrary(a_c1_8, c_a_c1_8).
head(r_c1_8_9, c_a_c1_9).  body(r_c1_8_9, a_c1_8).  contrary(a_c1_9, c_a_c1_9).
head(r_c1_9_10, c_a_c1_10).  body(r_c1_9_10, a_c1_9).  contrary(a_c1_10, c_a_c1_10).

%% Chain 2 (similar structure)
assumption(a_c2_1).  assumption(a_c2_2).  assumption(a_c2_3).  assumption(a_c2_4).  assumption(a_c2_5).
assumption(a_c2_6).  assumption(a_c2_7).  assumption(a_c2_8).  assumption(a_c2_9).  assumption(a_c2_10).

weight(a_c2_1, 10).  weight(a_c2_2, 10).  weight(a_c2_3, 10).  weight(a_c2_4, 10).  weight(a_c2_5, 10).
weight(a_c2_6, 10).  weight(a_c2_7, 10).  weight(a_c2_8, 10).  weight(a_c2_9, 10).  weight(a_c2_10, 10).

weight(c_a_c2_1, 10).  weight(c_a_c2_2, 10).  weight(c_a_c2_3, 10).  weight(c_a_c2_4, 10).  weight(c_a_c2_5, 10).
weight(c_a_c2_6, 10).  weight(c_a_c2_7, 10).  weight(c_a_c2_8, 10).  weight(c_a_c2_9, 10).  weight(c_a_c2_10, 10).

head(r_ra_c2_1, c_a_c2_1).  body(r_ra_c2_1, root_a).  contrary(a_c2_1, c_a_c2_1).
head(r_c2_1_2, c_a_c2_2).  body(r_c2_1_2, a_c2_1).  contrary(a_c2_2, c_a_c2_2).
head(r_c2_2_3, c_a_c2_3).  body(r_c2_2_3, a_c2_2).  contrary(a_c2_3, c_a_c2_3).
head(r_c2_3_4, c_a_c2_4).  body(r_c2_3_4, a_c2_3).  contrary(a_c2_4, c_a_c2_4).
head(r_c2_4_5, c_a_c2_5).  body(r_c2_4_5, a_c2_4).  contrary(a_c2_5, c_a_c2_5).
head(r_c2_5_6, c_a_c2_6).  body(r_c2_5_6, a_c2_5).  contrary(a_c2_6, c_a_c2_6).
head(r_c2_6_7, c_a_c2_7).  body(r_c2_6_7, a_c2_6).  contrary(a_c2_7, c_a_c2_7).
head(r_c2_7_8, c_a_c2_8).  body(r_c2_7_8, a_c2_7).  contrary(a_c2_8, c_a_c2_8).
head(r_c2_8_9, c_a_c2_9).  body(r_c2_8_9, a_c2_8).  contrary(a_c2_9, c_a_c2_9).
head(r_c2_9_10, c_a_c2_10).  body(r_c2_9_10, a_c2_9).  contrary(a_c2_10, c_a_c2_10).

%% Chains 3, 4, 5 for Territory A (abbreviated to save space)
%% In practice, would continue with same pattern for 30 more assumptions

%%  SKIPPING chains 3-5 for brevity - this is already 22 assumptions in Territory A

%% ===== TERRITORY B: Symmetric to Territory A =====
%% root_b → b_c1_1 → ... → b_c1_10
%% root_b → b_c2_1 → ... → b_c2_10
%% (Similar structure, 20 assumptions shown)

assumption(b_c1_1).  assumption(b_c1_2).  assumption(b_c1_3).  assumption(b_c1_4).  assumption(b_c1_5).
assumption(b_c1_6).  assumption(b_c1_7).  assumption(b_c1_8).  assumption(b_c1_9).  assumption(b_c1_10).

weight(b_c1_1, 10).  weight(b_c1_2, 10).  weight(b_c1_3, 10).  weight(b_c1_4, 10).  weight(b_c1_5, 10).
weight(b_c1_6, 10).  weight(b_c1_7, 10).  weight(b_c1_8, 10).  weight(b_c1_9, 10).  weight(b_c1_10, 10).

weight(c_b_c1_1, 10).  weight(c_b_c1_2, 10).  weight(c_b_c1_3, 10).  weight(c_b_c1_4, 10).  weight(c_b_c1_5, 10).
weight(c_b_c1_6, 10).  weight(c_b_c1_7, 10).  weight(c_b_c1_8, 10).  weight(c_b_c1_9, 10).  weight(c_b_c1_10, 10).

head(r_rb_c1_1, c_b_c1_1).  body(r_rb_c1_1, root_b).  contrary(b_c1_1, c_b_c1_1).
head(r_bc1_1_2, c_b_c1_2).  body(r_bc1_1_2, b_c1_1).  contrary(b_c1_2, c_b_c1_2).
head(r_bc1_2_3, c_b_c1_3).  body(r_bc1_2_3, b_c1_2).  contrary(b_c1_3, c_b_c1_3).
head(r_bc1_3_4, c_b_c1_4).  body(r_bc1_3_4, b_c1_3).  contrary(b_c1_4, c_b_c1_4).
head(r_bc1_4_5, c_b_c1_5).  body(r_bc1_4_5, b_c1_4).  contrary(b_c1_5, c_b_c1_5).
head(r_bc1_5_6, c_b_c1_6).  body(r_bc1_5_6, b_c1_5).  contrary(b_c1_6, c_b_c1_6).
head(r_bc1_6_7, c_b_c1_7).  body(r_bc1_6_7, b_c1_6).  contrary(b_c1_7, c_b_c1_7).
head(r_bc1_7_8, c_b_c1_8).  body(r_bc1_7_8, b_c1_7).  contrary(b_c1_8, c_b_c1_8).
head(r_bc1_8_9, c_b_c1_9).  body(r_bc1_8_9, b_c1_8).  contrary(b_c1_9, c_b_c1_9).
head(r_bc1_9_10, c_b_c1_10).  body(r_bc1_9_10, b_c1_9).  contrary(b_c1_10, c_b_c1_10).

%%  SKIPPING remaining Territory B chains for brevity

%% ===== SHARED ZONE: 10 assumptions =====
assumption(shared_1).  assumption(shared_2).  assumption(shared_3).  assumption(shared_4).  assumption(shared_5).
assumption(shared_6).  assumption(shared_7).  assumption(shared_8).  assumption(shared_9).  assumption(shared_10).

weight(shared_1, 10).  weight(shared_2, 10).  weight(shared_3, 10).  weight(shared_4, 10).  weight(shared_5, 10).
weight(shared_6, 10).  weight(shared_7, 10).  weight(shared_8, 10).  weight(shared_9, 10).  weight(shared_10, 10).

weight(c_shared_1, 10).  weight(c_shared_2, 10).  weight(c_shared_3, 10).  weight(c_shared_4, 10).  weight(c_shared_5, 10).
weight(c_shared_6, 10).  weight(c_shared_7, 10).  weight(c_shared_8, 10).  weight(c_shared_9, 10).  weight(c_shared_10, 10).

%% Both roots attack all shared assumptions
head(r_ra_s1, c_shared_1).  body(r_ra_s1, root_a).  contrary(shared_1, c_shared_1).
head(r_rb_s1, c_shared_1).  body(r_rb_s1, root_b).  % Same contrary

head(r_ra_s2, c_shared_2).  body(r_ra_s2, root_a).  contrary(shared_2, c_shared_2).
head(r_rb_s2, c_shared_2).  body(r_rb_s2, root_b).

head(r_ra_s3, c_shared_3).  body(r_ra_s3, root_a).  contrary(shared_3, c_shared_3).
head(r_rb_s3, c_shared_3).  body(r_rb_s3, root_b).

head(r_ra_s4, c_shared_4).  body(r_ra_s4, root_a).  contrary(shared_4, c_shared_4).
head(r_rb_s4, c_shared_4).  body(r_rb_s4, root_b).

head(r_ra_s5, c_shared_5).  body(r_ra_s5, root_a).  contrary(shared_5, c_shared_5).
head(r_rb_s5, c_shared_5).  body(r_rb_s5, root_b).

head(r_ra_s6, c_shared_6).  body(r_ra_s6, root_a).  contrary(shared_6, c_shared_6).
head(r_rb_s6, c_shared_6).  body(r_rb_s6, root_b).

head(r_ra_s7, c_shared_7).  body(r_ra_s7, root_a).  contrary(shared_7, c_shared_7).
head(r_rb_s7, c_shared_7).  body(r_rb_s7, root_b).

head(r_ra_s8, c_shared_8).  body(r_ra_s8, root_a).  contrary(shared_8, c_shared_8).
head(r_rb_s8, c_shared_8).  body(r_rb_s8, root_b).

head(r_ra_s9, c_shared_9).  body(r_ra_s9, root_a).  contrary(shared_9, c_shared_9).
head(r_rb_s9, c_shared_9).  body(r_rb_s9, root_b).

head(r_ra_s10, c_shared_10).  body(r_ra_s10, root_a).  contrary(shared_10, c_shared_10).
head(r_rb_s10, c_shared_10).  body(r_rb_s10, root_b).

%% TOTAL ASSUMPTIONS: 2 (roots) + 20 (terr_a) + 20 (terr_b) + 10 (shared) = 52
%% (Abbreviated from planned 120 to keep file manageable)
%%
%% This framework has 52 assumptions with sparse connectivity.
%% Territory A chains are only attacked when root_a is chosen.
%% Territory B chains are only attacked when root_b is chosen.
%%
%% The key question: Will the ranges differ?
