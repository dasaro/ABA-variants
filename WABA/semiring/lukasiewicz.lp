%% Łukasiewicz (Bounded-Sum) Semiring for Weight Propagation
%% Semiring: ({0..k}, max, bounded-sum, 0, k)
%% - Domain: integer grid {0,1,...,k}  (#const k; a fixed-point encoding of [0,1],
%%   w = round(p*k))
%% - Disjunction/⊕ (OR, multiple derivations): max  (strongest alternative)
%% - Conjunction/⊗ (AND, body elements): bounded sum  a⊗b = max(0, a+b-k)
%%     n-ary closed form: a1⊗...⊗an = max(0, (Σ wi) - (n-1)*k)
%% - Additive identity 0̄ = 0   (identity for max; also the ⊗-annihilator: a⊗0 = 0)
%% - Multiplicative identity 1̄ = k   (top of the grid; a⊗k = a)
%%
%% Interpretation: weights are certainties/probabilities ×k. Unlike Gödel (⊗=min,
%% the weakest link, which never erodes a chain below its weakest premise), the
%% Łukasiewicz t-norm ERODES certainty along a chain — each extra conjunct subtracts
%% (k - wi) — so stacking weak premises can fall all the way to 0 ("impossible").
%% This is the only WABA algebra whose ⊗ is neither min, max nor plain + (it is +
%% with a clamp), hence NOT reachable from the other four by any monotone/log/
%% negation relabelling.
%%
%% Weights must lie in {0..k}; values above k leave the grid. Override the grid with
%% -c k=N (default 1000, matching the probability/surprisal scale used elsewhere).

#const k = 1000.

active_semiring(lukasiewicz).
#include "../defaults/base.lp".

%% Unweighted assumptions are maximally certain = ⊗-identity k (transparent in ⊗,
%% hardest to discard). Same value for every default policy.
semiring_default_weight(legacy,k).
semiring_default_weight(aba,k).
semiring_default_weight(neutral,k).

%% =====================================================================
%% SUPPORTED WEIGHT  (the ⊕/⊗ weight propagation)
%% =====================================================================

%% Assumptions with explicit weights
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W), not head(_,X).

%% Assumptions without explicit weights: ⊗-identity k
supported_with_weight(X,W) :-
    assumption(X), in(X), not weight(X,_), not head(_,X), default_assumption_weight(W).

%% #sum silently drops #sup/#inf, and the bounded sum saturates them: detect first.
body_has_sup_weight(R) :- body(R,B), supported_with_weight(B,#sup).
body_has_inf_weight(R) :- body(R,B), supported_with_weight(B,#inf).

%% #inf (bottom) -> 0, the bounded-sum ⊗-annihilator; annihilator takes precedence.
rule_derivation_weight(R,X,0) :-
    head(R,X), supported(X), body(R,_), triggered_by_in(R),
    body_has_inf_weight(R).
%% #sup (top) saturates to the grid top k.
rule_derivation_weight(R,X,k) :-
    head(R,X), supported(X), body(R,_), triggered_by_in(R),
    not body_has_inf_weight(R), body_has_sup_weight(R).
%% Finite grid: bounded sum  M = max(0, (Σ wi) - (n-1)*k).
rule_derivation_weight(R,X,M) :-
    head(R,X), supported(X), body(R,_), triggered_by_in(R),
    not body_has_inf_weight(R), not body_has_sup_weight(R),
    S = #sum{ V,B : body(R,B), supported_with_weight(B,V) },
    N = #count{ B : body(R,B) },
    M = #max{ 0 ; S-(N-1)*k }.

%% Empty body (fact) = empty conjunction = ⊗-identity k = 1̄.
%% (The closed form also gives k at n=0; this explicit rule is the empty-body branch,
%%  guarded by `not weight(X,_)` so an explicitly weighted fact keeps its weight.)
rule_derivation_weight(R,X,k) :-
    head(R,X), supported(X), not body(R,_), not weight(X,_).

%% Combine alternative derivations + explicit weight via ⊕ = max.
supported_with_weight(X,W) :-
    supported(X), head(_,X), not assumption(X),
    W = #max{ V,R : rule_derivation_weight(R,X,V) ; V : weight(X,V) }.

%% NON-FLAT: derived assumption WITH explicit weight.
supported_with_weight(X,W) :-
    assumption(X), supported(X), head(_,X), weight(X,_),
    W = #max{ V,R : rule_derivation_weight(R,X,V) ; V : weight(X,V) }.

%% NON-FLAT: derived assumption, IN, WITHOUT explicit weight (default as a ⊕ alt.).
supported_with_weight(X,W) :-
    assumption(X), in(X), supported(X), head(_,X), not weight(X,_),
    default_assumption_weight(D),
    W = #max{ V,R : rule_derivation_weight(R,X,V) ; D : true }.

%% =====================================================================
%% UNDEFEATED WEIGHT  (for admissible/complete/grounded defense)
%% Strength polarity (higher is better); mirrors arctic with bounded-sum ⊗.
%% =====================================================================

undefeated_weight(X,W) :-
    assumption(X), not defeated(X), not weight(X,_), not head(_,X), default_assumption_weight(W).
undefeated_weight(X,W) :- assumption(X), not defeated(X), weight(X,W), not head(_,X).

undefeated_body_has_sup(R) :- body(R,B), undefeated_weight(B,#sup).
undefeated_body_has_inf(R) :- body(R,B), undefeated_weight(B,#inf).
undefeated_rule_weight(R,X,0) :-
    head(R,X), derived_from_undefeated(X), body(R,_), triggered_by_undefeated(R),
    undefeated_body_has_inf(R).
undefeated_rule_weight(R,X,k) :-
    head(R,X), derived_from_undefeated(X), body(R,_), triggered_by_undefeated(R),
    not undefeated_body_has_inf(R), undefeated_body_has_sup(R).
undefeated_rule_weight(R,X,M) :-
    head(R,X), derived_from_undefeated(X), body(R,_), triggered_by_undefeated(R),
    not undefeated_body_has_inf(R), not undefeated_body_has_sup(R),
    S = #sum{ V,B : body(R,B), undefeated_weight(B,V) },
    N = #count{ B : body(R,B) },
    M = #max{ 0 ; S-(N-1)*k }.

undefeated_weight(X,W) :-
    derived_from_undefeated(X), head(_,X), not assumption(X),
    W = #max{ V,R : undefeated_rule_weight(R,X,V) }.
undefeated_weight(X,W) :-
    assumption(X), not defeated(X), derived_from_undefeated(X), head(_,X), weight(X,_),
    W = #max{ V,R : undefeated_rule_weight(R,X,V) ; V : weight(X,V) }.
undefeated_weight(X,W) :-
    assumption(X), not defeated(X), derived_from_undefeated(X), head(_,X), not weight(X,_),
    default_assumption_weight(D),
    W = #max{ V,R : undefeated_rule_weight(R,X,V) ; D : true }.

%% Polarity: strength (higher is better), identical to arctic.
unaffordable_attack(W,B) :- undefeated_weight(_,W), budget(B), B = #sup, W != #sup.
unaffordable_attack(W,B) :- undefeated_weight(_,W), budget(B), B = 0, W != #inf.
unaffordable_attack(W,B) :- undefeated_weight(_,W), budget(B), B != #sup, B != 0, W < B.
