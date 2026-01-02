%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Semi-stable ⊂ Preferred (Proper WABA Format)
%%
%% Based on: test/strict_inclusions/semistable_preferred_asym.lp
%% Converted to use derived atoms instead of direct contrary relations
%%
%% GOAL: Achieve semi-stable ⊂ preferred (strict inclusion)
%%
%% STRUCTURE:
%%   Arguments: a, b, c, d, e
%%   Attacks: a↔b (mutual), b→c, c→d, c→e, e→e (self-attack)
%%
%% EXPECTED (with budget=0):
%%   Complete: {a,c}, {b,d}
%%   Preferred: {a,c}, {b,d} (both maximal, incomparable)
%%   Semi-stable: {a,c} only (maximal range)
%%
%% RANGES:
%%   - range({a,c}) = {a, b(attacked), c, d(attacked), e(attacked)} = 5
%%   - range({b,d}) = {a(attacked), b, c(attacked), d} = 4 (missing e!)
%%
%% KEY: e is self-attacking, so if e is out, the attack e→e doesn't fire,
%%      making e unreachable from extension {b,d}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(0).  %% No attack discarding - classical ABA behavior

assumption(a).
assumption(b).
assumption(c).
assumption(d).
assumption(e).

weight(a, 100).
weight(b, 100).
weight(c, 100).
weight(d, 100).
weight(e, 100).

%% Derived atoms for attacks
weight(c_a, 100).  % contrary of a (attacked by b)
weight(c_b, 100).  % contrary of b (attacked by a)
weight(c_c, 100).  % contrary of c (attacked by b)
weight(c_d, 100).  % contrary of d (attacked by c)
weight(c_e, 100).  % contrary of e (attacked by c and e itself)

%% a → b (a attacks b via derived atom c_b)
head(r_a_b, c_b).
body(r_a_b, a).
contrary(b, c_b).

%% b → a (b attacks a via derived atom c_a)
head(r_b_a, c_a).
body(r_b_a, b).
contrary(a, c_a).

%% b → c (b attacks c via derived atom c_c)
head(r_b_c, c_c).
body(r_b_c, b).
contrary(c, c_c).

%% c → d (c attacks d via derived atom c_d)
head(r_c_d, c_d).
body(r_c_d, c).
contrary(d, c_d).

%% c → e (c attacks e via derived atom c_e)
head(r_c_e, c_e).
body(r_c_e, c).
contrary(e, c_e).

%% e → e (e self-attacks)
%% Self-attack means e cannot be in any extension (violates conflict-free)
%% But when e is out, this attack doesn't fire, so e is unreachable
head(r_e_e, c_e).
body(r_e_e, e).
%% Already defined: contrary(e, c_e).

%% Analysis:
%% Extension 1: {a, c}
%%   - a is in → r_a_b fires → c_b is derived → b is attacked → b is out
%%   - c is in → r_c_d fires → c_d is derived → d is attacked → d is out
%%   - c is in → r_c_e fires → c_e is derived → e is attacked → e is out
%%   - Range = {a, b, c, d, e} (all 5 assumptions covered)
%%
%% Extension 2: {b, d}
%%   - b is in → r_b_a fires → c_a is derived → a is attacked → a is out
%%   - b is in → r_b_c fires → c_c is derived → c is attacked → c is out
%%   - d is in (unattacked since c is out, so r_c_d doesn't fire)
%%   - e is out (self-attack if in), and since c is out, r_c_e doesn't fire
%%   - e is out and no attack on e fires → e is unattacked
%%   - Wait, if e is unattacked, then e is defended, so e MUST be in (completeness)!
%%
%% ISSUE: This might not work as expected because of completeness requirement!
%% Let me reconsider...
%%
%% If e has self-attack e→e:
%%   - If e is in → r_e_e fires → c_e is derived → e is attacked → CONFLICT!
%%   - So e cannot be in (conflict-free violation)
%%   - If e is out and no other attack on e → e is DEFENDED (vacuously)
%%   - Defended arguments must be in (completeness) → CONTRADICTION!
%%
%% This means e with ONLY self-attack cannot exist in any complete extension.
%% The framework becomes UNSATISFIABLE if we require completeness!
%%
%% To fix: e needs an external attack so it can be validly out
