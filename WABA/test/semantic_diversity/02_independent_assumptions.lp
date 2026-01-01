%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Independent Assumptions (No Attacks)
%%
%% GOAL: Multiple complete extensions via independence
%%
%% STRUCTURE:
%%   a, b, c are independent (no attacks between them)
%%
%% EXPECTED SEMANTICS (β=100):
%%   - Complete: {a,b,c} (only one - all in)
%%   - Preferred: {a,b,c} (maximal)
%%   - Grounded: {a,b,c} (all unattacked)
%%   - Stable: {a,b,c}
%%
%% NOTE: This creates semantic EQUALITY, not diversity
%%       But useful as baseline for comparison
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).

assumption(a).
assumption(b).
assumption(c).

weight(a, 10).
weight(b, 20).
weight(c, 30).

%% No attacks - all assumptions are unattacked
%% (contraries exist but never triggered)
contrary(a, a).
contrary(b, b).
contrary(c, c).
