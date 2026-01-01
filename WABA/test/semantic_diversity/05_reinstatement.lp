%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Reinstatement Pattern
%%
%% GOAL: Create grounded ⊂ preferred via reinstatement
%%
%% STRUCTURE (Classic reinstatement example):
%%   a is unattacked (grounded)
%%   b attacks c
%%   c attacks b (mutual)
%%   a defends d (a attacks attacker of d)
%%
%% SIMPLIFIED FOR WABA:
%%   a - unattacked assumption
%%   b, c - mutually attacking assumptions
%%   d - attacked by c, but a reinstates d
%%
%% ATTACK GRAPH:
%%   b → c
%%   c → b (mutual attack)
%%   c → d
%%   No attack on a
%%
%% EXPECTED SEMANTICS:
%%   - Grounded: {a} (only unattacked)
%%   - Complete: {a}, {a,b}, {a,c} (a + one of the mutual attackers)
%%   - Preferred: {a,b}, {a,c} (maximal, excluding just {a})
%%
%% KEY DISTINCTION: Grounded ⊂ Preferred (strict)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).

assumption(a).
assumption(b).
assumption(c).
assumption(d).

weight(a, 10).
weight(b, 20).
weight(c, 20).
weight(d, 10).

%% Derived atoms and contraries
weight(c_b, 20).
weight(c_c, 20).
weight(c_d, 20).

%% b attacks c
head(r_b_c, c_c).
body(r_b_c, b).
contrary(c, c_c).

%% c attacks b
head(r_c_b, c_b).
body(r_c_b, c).
contrary(b, c_b).

%% c attacks d
head(r_c_d, c_d).
body(r_c_d, c).
contrary(d, c_d).

%% a has no attacks (unattacked, will be in grounded)
contrary(a, a).  % Self-loop as placeholder
