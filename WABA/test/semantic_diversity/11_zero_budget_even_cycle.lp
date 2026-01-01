%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Zero Budget - No Discarding Allowed
%%
%% GOAL: Force grounded ⊂ complete with NO discarding choices
%%
%% STRATEGY: Set budget(0) - NO attacks can be discarded!
%%           Attack graph is completely fixed
%%           Classic even cycle structure
%%
%% STRUCTURE:
%%   - u is unattacked
%%   - a and b attack each other mutually
%%
%% With budget(0), the attacks a→b and b→a cannot be discarded.
%% This creates a fixed attack graph.
%%
%% EXPECTED SEMANTICS (β=0, no discarding possible):
%%   - Grounded: {u} (only unattacked assumption)
%%   - Stable: ∅ (no stable - even cycle)
%%   - Complete: {u,a}, {u,b} (two complete extensions)
%%   - Preferred: {u,a}, {u,b} (both maximal)
%%   - Semi-stable: {u,a}, {u,b} (assuming equal ranges)
%%
%% KEY DISTINCTION: Grounded ⊂ Complete (STRICT!)
%%                  Grounded has 1 extension, Complete has 2
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(0).  %% CRITICAL: No attacks can be discarded!

assumption(u).
assumption(a).
assumption(b).

weight(u, 10).
weight(a, 20).
weight(b, 20).

%% Derived atoms for indirect attacks
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

%% u is unattacked
contrary(u, u).  % Self-loop placeholder
