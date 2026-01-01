%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Force Grounded ⊂ Complete (Strict)
%%
%% GOAL: Create framework where grounded is strictly smaller than complete
%%
%% STRATEGY: Classic even cycle with unattacked argument
%%   - u is unattacked (grounded extension)
%%   - a, b form even cycle (attack each other)
%%   - Both {u,a} and {u,b} are complete
%%   - Only {u} is grounded (minimal)
%%
%% ATTACK GRAPH (no attacks on u, symmetric a-b):
%%   a ⟷ b (with zero-weight attacks to avoid discarding choices)
%%   u unattacked
%%
%% EXPECTED:
%%   - Grounded: {u}
%%   - Complete: {u,a}, {u,b}
%%   - Preferred: {u,a}, {u,b}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).

assumption(u).
assumption(a).
assumption(b).

weight(u, 10).
weight(a, 10).
weight(b, 10).

%% Zero-weight attacks to prevent discarding from creating new scenarios
weight(c_a, 0).
weight(c_b, 0).

%% a attacks b
head(r_a_b, c_b).
body(r_a_b, a).
contrary(b, c_b).

%% b attacks a
head(r_b_a, c_a).
body(r_b_a, b).
contrary(a, c_a).

%% u is unattacked
contrary(u, u).
