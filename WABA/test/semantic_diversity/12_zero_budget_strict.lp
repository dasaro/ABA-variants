%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Zero Budget with True Unattacked Assumption
%%
%% GOAL: grounded ⊂ complete with budget(0) (no discarding)
%%
%% STRATEGY: Fixed attack graph via budget(0)
%%           One truly unattacked assumption
%%           Even cycle for the others
%%
%% STRUCTURE:
%%   - u is unattacked (no contrary points to u)
%%   - a and b attack each other mutually
%%
%% EXPECTED (β=0):
%%   - Grounded: {u} (only unattacked)
%%   - Complete: {u,a}, {u,b} (u + one from the cycle)
%%   - Preferred: {u,a}, {u,b}
%%
%% KEY: grounded ⊂ complete (1 extension vs 2 extensions)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(0).

assumption(u).
assumption(a).
assumption(b).

weight(u, 10).
weight(a, 20).
weight(b, 20).

%% Derived atoms
weight(d_a, 20).
weight(d_b, 20).
weight(c_a, 20).
weight(c_b, 20).

%% a → d_b → c_b (a attacks b)
head(r_a_db, d_b).
body(r_a_db, a).

head(r_db_cb, c_b).
body(r_db_cb, d_b).

contrary(b, c_b).

%% b → d_a → c_a (b attacks a)
head(r_b_da, d_a).
body(r_b_da, b).

head(r_da_ca, c_a).
body(r_da_ca, d_a).

contrary(a, c_a).

%% u is truly unattacked - use a DIFFERENT atom as its contrary
%% Create a dummy contrary that's never derived
assumption(dummy).
weight(dummy, 1).
contrary(u, never_happens).
weight(never_happens, 1).

%% Make dummy's contrary also unreachable
contrary(dummy, also_never_happens).
weight(also_never_happens, 1).
