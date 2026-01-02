%% Framework demonstrating: stable ⊂ semi-stable (strict)
%%
%% Strategy: Use a "bad" self-attacking assumption v that blocks defeating u
%%
%% Assumptions: a, b, u, v
%% Rules (1-step deductions):
%%   ca :- b.   (b attacks a)
%%   cb :- a.   (a attacks b)
%%   cu :- v.   (v attacks u, but v can never be in - self-attack)
%%   cv :- v.   (v attacks itself)
%%
%% Expected:
%% - Stable: ∅ (u cannot be defeated since v can't be in any conflict-free set)
%% - Semi-stable: {a}, {b} (both admissible with maximal range {a,b})
%%
%% Analysis:
%% - {a} is admissible: a defends against ca (ca requires b, which is out)
%% - {b} is admissible: b defends against cb (cb requires a, which is out)
%% - v can never be in (self-attack cv :- v)
%% - u cannot be defeated (only cu :- v defeats u, but v can't be in)
%% - {u} is NOT admissible (v is undefeated → cu derivable → u attacked by undefeated)
%% - No stable extension exists (u must be in or defeated, but can't be defeated,
%%   and if u is in, then v must be defeated, but v can't be defeated without being in)

assumption(a).
assumption(b).
assumption(u).
assumption(v).

%% Contraries (total function - one per assumption)
contrary(a, ca).
contrary(b, cb).
contrary(u, cu).
contrary(v, cv).

%% Rules that induce attacks
%% ca :- b  (if b is supported, then ca is supported, attacking a)
head(r_ca, ca).
body(r_ca, b).

%% cb :- a  (if a is supported, then cb is supported, attacking b)
head(r_cb, cb).
body(r_cb, a).

%% cu :- v  (if v is supported, then cu is supported, attacking u)
head(r_cu, cu).
body(r_cu, v).

%% cv :- v  (if v is supported, then cv is supported, attacking v itself!)
head(r_cv, cv).
body(r_cv, v).

%% Weights
weight(a, 100).
weight(b, 100).
weight(u, 100).
weight(v, 100).
weight(ca, 100).
weight(cb, 100).
weight(cu, 100).
weight(cv, 100).

#const beta = 0.
budget(beta).
