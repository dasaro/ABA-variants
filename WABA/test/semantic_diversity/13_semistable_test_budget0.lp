%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Semi-stable vs Preferred with budget(0)
%%
%% GOAL: Distinguish semi-stable from preferred by preventing attack discarding
%%
%% STRATEGY: Set budget(0) to make WABA behave like classical ABA
%%           Use classical ABA pattern known to separate semi-stable from preferred
%%
%% STRUCTURE (classical ABA example):
%%   - a is unattacked
%%   - b is attacked by a
%%   - c is unattacked and independent
%%   - d is attacked by c
%%   - e is unattacked and independent
%%
%% ATTACK GRAPH (fixed, no discarding):
%%   a → b
%%   c → d
%%
%% EXPECTED SEMANTICS (budget=0, fixed graph):
%%   - Complete: {a,c,e}, {a,c}, {a,e}, {a}
%%   - Preferred: {a,c,e}, {a,c}, {a,e}  (maximal complete)
%%   - Semi-stable: {a,c,e} only (maximal range)
%%     * {a,c,e}: range = {a,b,c,d,e} (all assumptions covered)
%%     * {a,c}: range = {a,b,c,d} (missing e)
%%     * {a,e}: range = {a,b,e} (missing c,d)
%%
%% KEY DISTINCTION: Semi-stable ⊂ Preferred (1 vs 3 extensions)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(0).  %% CRITICAL: No attack discarding allowed!

assumption(a).
assumption(b).
assumption(c).
assumption(d).
assumption(e).

weight(a, 10).
weight(b, 10).
weight(c, 10).
weight(d, 10).
weight(e, 10).

weight(c_b, 10).
weight(c_d, 10).

%% a → b (a attacks b)
head(r_a_b, c_b).
body(r_a_b, a).
contrary(b, c_b).

%% c → d (c attacks d)
head(r_c_d, c_d).
body(r_c_d, c).
contrary(d, c_d).

%% a, c, e are unattacked (no contrary atoms derived for them)
contrary(a, never_a).
contrary(c, never_c).
contrary(e, never_e).

weight(never_a, 1).
weight(never_c, 1).
weight(never_e, 1).
