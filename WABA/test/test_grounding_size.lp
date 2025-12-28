%%% Test case to diagnose grounding explosion
%%% Framework with r=5 rules per assumption, d=2 derivation depth

%% 5 assumptions
assumption(a1).
assumption(a2).
assumption(a3).
assumption(a4).
assumption(a5).

%% Weights
weight(a1, 10).
weight(a2, 20).
weight(a3, 30).
weight(a4, 40).
weight(a5, 50).

%% 5 rules per assumption (r=5)
head(r1, d1); body(r1, a1); body(r1, a2).
head(r2, d1); body(r2, a2); body(r2, a3).
head(r3, d1); body(r3, a3); body(r3, a4).
head(r4, d1); body(r4, a4); body(r4, a5).
head(r5, d1); body(r5, a5); body(r5, a1).

%% Second level derivation (d=2)
head(r6, d2); body(r6, d1); body(r6, a1).
head(r7, d2); body(r7, d1); body(r7, a2).
head(r8, d2); body(r8, d1); body(r8, a3).
head(r9, d2); body(r9, d1); body(r9, a4).
head(r10, d2); body(r10, d1); body(r10, a5).

%% Contraries (create attacks)
contrary(a1, a2).
contrary(a2, a3).
contrary(a3, a4).
contrary(a4, a5).
contrary(a5, a1).

%% Budget
budget(100).
