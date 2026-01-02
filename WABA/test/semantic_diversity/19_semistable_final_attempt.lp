%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Semi-stable ⊂ Preferred (Using Self-Attack Strategy)
%%
%% KEY INSIGHT: Use self-attacking "dummy" assumptions to create assumptions
%%              that can be in range (when attacked) but never in extensions
%%
%% STRUCTURE:
%%
%%   Core choice: a ↔ b (mutual exclusion)
%%
%%   Peripheral self-attackers: {s1, s2, s3}
%%     - si → si (self-attack, can NEVER be in any extension)
%%     - Only 'a' attacks these self-attackers
%%
%%   Chain: c → d
%%
%% Expected Extensions:
%%
%%   E1 = {a, c}:
%%     - a attacks b → b out
%%     - a attacks s1, s2, s3 → all out (would be out anyway due to self-attack)
%%     - c unattacked → c in (completeness)
%%     - c attacks d → d out
%%     - Range = {a, b(att), c, d(att), s1(att), s2(att), s3(att)} = 7
%%
%%   E2 = {b, c}:
%%     - b attacks a → a out
%%     - a out → s1, s2, s3 NOT attacked by anyone (a's attacks don't fire)
%%     - s1, s2, s3 have only self-attacks
%%     - When si is out, si→si doesn't fire (si not supported)
%%     - So si has NO attacks when out
%%     - si unattacked → si defended → si must be in??? NO!
%%
%% ISSUE: Self-attack paradox again!
%%   If si is out → si→si doesn't fire → si unattacked → si defended
%%   → si must be in (completeness) → BUT si cannot be in (self-attack conflict)
%%
%% This creates UNSATISFIABILITY for E2!
%%
%% SOLUTION: si must have EXTERNAL attack to be validly out
%%   Add: b → s1, b → s2, b → s3
%%
%% Then:
%%   E1 = {a, c}: a attacks {b, s1, s2, s3}, c attacks d
%%     - Range = {a, b, c, d, s1, s2, s3} = 7
%%
%%   E2 = {b, c}: b attacks {a, s1, s2, s3}, c attacks d
%%     - Range = {a, b, c, d, s1, s2, s3} = 7
%%
%% SAME RANGE STILL!
%%
%% The fundamental problem: in a connected framework, every assumption ends up
%% in the range of every extension one way or another.
%%
%% FINAL ATTEMPT: Create DISCONNECTED components
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(0).

%% Component 1: Mutual exclusion
assumption(a).
assumption(b).

weight(a, 10).
weight(b, 10).
weight(c_a, 10).
weight(c_b, 10).

head(r_a_b, c_b).
body(r_a_b, a).
contrary(b, c_b).

head(r_b_a, c_a).
body(r_b_a, b).
contrary(a, c_a).

%% Component 2: Chain (connected to component 1 via 'a')
assumption(c).
assumption(d).
assumption(e).

weight(c, 10).
weight(d, 10).
weight(e, 10).
weight(c_c, 10).
weight(c_d, 10).
weight(c_e, 10).

%% a → c
head(r_a_c, c_c).
body(r_a_c, a).
contrary(c, c_c).

%% c → d
head(r_c_d, c_d).
body(r_c_d, c).
contrary(d, c_d).

%% d → e
head(r_d_e, c_e).
body(r_d_e, d).
contrary(e, c_e).

%% Expected:
%% E1 = {a}: a attacks {b, c}, c out → d unattacked → d in, d attacks e → e out
%%    Actually: {a, d}
%%    Range = {a, b, c, d, e} = 5
%%
%% E2 = {b}: b attacks a, a out → c unattacked → c in, c attacks d, d out → e unattacked → e in
%%    Actually: {b, c, e}
%%    Range = {a, b, c, d, e} = 5
%%
%% STILL SAME RANGE!

%% I give up on this manually. Let me just use the user's suggestion:
%% Find a working classical ABA example and convert it.
