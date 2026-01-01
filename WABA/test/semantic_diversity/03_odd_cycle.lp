%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Odd Cycle (3-cycle)
%%
%% GOAL: No stable extensions, but multiple complete extensions
%%
%% STRUCTURE:
%%   a → d_b → c_b (a attacks b via derived atom)
%%   b → d_c → c_c (b attacks c via derived atom)
%%   c → d_a → c_a (c attacks a via derived atom)
%%
%% EXPECTED SEMANTICS (β=100):
%%   - Complete: ∅ (empty is the only complete)
%%   - Preferred: ∅
%%   - Grounded: ∅
%%   - Stable: ∅ (no stable in odd cycle)
%%   - Semi-stable: ∅
%%
%% KEY DISTINCTION: All semantics should agree on ∅
%%
%% NOTE: In WABA with discarding, we could discard attacks to break cycle
%%       At different budgets, we get different attack graphs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).

assumption(a).
assumption(b).
assumption(c).

weight(a, 30).
weight(b, 30).
weight(c, 30).

%% Derived atoms for attacks
weight(d_a, 30).
weight(d_b, 30).
weight(d_c, 30).

weight(c_a, 30).
weight(c_b, 30).
weight(c_c, 30).

%% Rules: a → d_b
head(r_ab, d_b).
body(r_ab, a).

%% b → d_c
head(r_bc, d_c).
body(r_bc, b).

%% c → d_a
head(r_ca, d_a).
body(r_ca, c).

%% Derived atoms produce contraries
head(r_attack_a, c_a).
body(r_attack_a, d_a).

head(r_attack_b, c_b).
body(r_attack_b, d_b).

head(r_attack_c, c_c).
body(r_attack_c, d_c).

%% Contraries
contrary(a, c_a).
contrary(b, c_b).
contrary(c, c_c).
