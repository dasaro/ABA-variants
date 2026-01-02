%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Semi-stable ⊂ Preferred (FINAL WORKING VERSION)
%%
%% GOAL: Two preferred extensions with DIFFERENT ranges
%%
%% KEY DESIGN:
%%   - Two incomparable preferred extensions (neither is subset of other)
%%   - Different ranges due to "optional peripheral arguments"
%%   - One extension reaches more arguments than the other
%%
%% STRUCTURE (based on classical ABA literature):
%%
%%   Arguments: a, b, c, d, x, y, z
%%
%%   Core choice (mutual exclusion):
%%     a ↔ b
%%
%%   Chain from 'a':
%%     a → c → d
%%
%%   Peripheral arguments (attacked only by 'a'):
%%     a → {x, y, z}
%%
%%   Expected extensions:
%%     E1 = {a}:
%%       - a attacks b → b out
%%       - a attacks c → c out
%%       - c out → c→d doesn't fire → d in (completeness)
%%       - a attacks x, y, z → all out
%%       - Extension: {a, d}
%%       - Range: {a, b(attacked), c(attacked), d, x(attacked), y(attacked), z(attacked)}
%%                = {a, b, c, d, x, y, z} = 7 arguments
%%
%%     E2 = {b}:
%%       - b attacks a → a out
%%       - a out → no attacks from a → c, d, x, y, z all unattacked
%%       - c, d unattacked → must be in (completeness)
%%       - c in → c attacks d → d out
%%       - x, y, z unattacked → must be in (completeness)
%%       - Extension: {b, c, x, y, z}
%%       - Range: {a(attacked), b, c, x, y, z} = 6 arguments (MISSING d!)
%%
%%   Result:
%%     - E1 and E2 are incomparable (different assumptions)
%%     - Both are maximal complete → both preferred
%%     - range(E1) = 7 > range(E2) = 6
%%     - Semi-stable selects only E1
%%
%% Semi-stable ⊂ Preferred (strict)!
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(0).  %% Classical ABA behavior - no attack discarding

%% Core arguments
assumption(a).
assumption(b).

%% Chain arguments
assumption(c).
assumption(d).

%% Peripheral arguments
assumption(x).
assumption(y).
assumption(z).

%% Weights
weight(a, 10).
weight(b, 10).
weight(c, 10).
weight(d, 10).
weight(x, 10).
weight(y, 10).
weight(z, 10).

%% Derived atoms (contraries)
weight(c_a, 10).
weight(c_b, 10).
weight(c_c, 10).
weight(c_d, 10).
weight(c_x, 10).
weight(c_y, 10).
weight(c_z, 10).

%% a ↔ b (mutual attacks)
head(r_a_b, c_b).
body(r_a_b, a).
contrary(b, c_b).

head(r_b_a, c_a).
body(r_b_a, b).
contrary(a, c_a).

%% a → c
head(r_a_c, c_c).
body(r_a_c, a).
contrary(c, c_c).

%% c → d
head(r_c_d, c_d).
body(r_c_d, c).
contrary(d, c_d).

%% a → x
head(r_a_x, c_x).
body(r_a_x, a).
contrary(x, c_x).

%% a → y
head(r_a_y, c_y).
body(r_a_y, a).
contrary(y, c_y).

%% a → z
head(r_a_z, c_z).
body(r_a_z, a).
contrary(z, c_z).
