%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Preferred vs Semi-stable Distinction
%%
%% GOAL: Create semi-stable ⊂ preferred (strict)
%%
%% DESIGN: Two preferred extensions with different ranges
%%   Extension 1: Larger assumption set, smaller range
%%   Extension 2: Smaller assumption set, larger range
%%
%% STRUCTURE:
%%   a, b - independent, both unattacked (both always in)
%%   c, d - mutually exclusive (c attacks d, d attacks c)
%%   e - attacked by d only
%%
%% ATTACK GRAPH:
%%   c ⟷ d (mutual)
%%   d → e
%%
%% EXPECTED SEMANTICS:
%%   - Complete: {a,b,c}, {a,b,d}
%%   - Preferred: {a,b,c}, {a,b,d} (both maximal)
%%   - Semi-stable:
%%     * {a,b,c}: range = {a,b,c,d} (d is attacked by c)
%%     * {a,b,d}: range = {a,b,d,e} (d is in, e is attacked by d)
%%     * If ranges differ, semi-stable selects one with max range
%%   - Grounded: {a,b} (only unattacked)
%%
%% KEY DISTINCTION: Semi-stable ⊂ Preferred if ranges differ
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).

assumption(a).
assumption(b).
assumption(c).
assumption(d).
assumption(e).

weight(a, 10).
weight(b, 10).
weight(c, 20).
weight(d, 20).
weight(e, 15).

weight(c_c, 20).
weight(c_d, 20).
weight(c_e, 20).

%% a and b are unattacked (always in grounded)
contrary(a, a).
contrary(b, b).

%% c attacks d
head(r_c_d, c_d).
body(r_c_d, c).
contrary(d, c_d).

%% d attacks c
head(r_d_c, c_c).
body(r_d_c, d).
contrary(c, c_c).

%% d attacks e
head(r_d_e, c_e).
body(r_d_e, d).
contrary(e, c_e).
