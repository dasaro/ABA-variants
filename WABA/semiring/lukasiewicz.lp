%% Łukasiewicz Semiring for Weight Propagation - OPTIMIZED
%% Semiring: ([0,K] ∪ {±∞}, ⊕_Ł, ⊗_Ł, 0, K)
%% - Domain: [0,K] ∪ {±∞} where K is the normalization constant (default K=100)
%% - Disjunction/⊕_Ł (OR): bounded sum min(K, a + b)
%% - Conjunction/⊗_Ł (AND): bounded sum max(0, a + b - K*(n-1))
%% - Additive identity (disjunction): 0
%% - Multiplicative identity (conjunction): K
%% - Interpretation: weights are truth degrees, higher is better
%% - Normalization constant K: parametrizable via CLI (default K=100)
%% - Default weight for unweighted assumptions: #sup
%%
%% OPTIMIZATION NOTES:
%% ===================
%% This version attempts to inline body_count and body_sum helpers to reduce grounding overhead.
%% Strategy: Combine count and sum operations directly in rule_derivation_weight computation.
%%
%% Original had 3 helpers:
%% 1. body_has_sup_weight - KEPT (necessary for #sum limitation)
%% 2. body_count - REMOVED (inlined into derivation rule)
%% 3. body_sum - REMOVED (inlined into derivation rule)
%%
%% Expected improvement: 30-40% reduction in grounding overhead

#const luk_k = 100.
active_semiring(lukasiewicz).
#include "../defaults/base.lp".

semiring_default_weight(legacy,#sup).
semiring_default_weight(aba,#sup).
semiring_default_weight(neutral,luk_k).

%% =============================================
%% CLASSICAL ABA RECOVERY (No Discarding)
%% =============================================
%%
%% To recover plain unweighted ABA behavior with this semiring:
%%
%% UPPER BOUND REGIME (MAX, SUM, COUNT monoids):
%%   δ = #sup     (default weight for unweighted assumptions)
%%   β = 0        (budget value)
%%   Mechanism: constraint/ub.lp explicitly rejects discarding #sup-weighted attacks
%%
%% LOWER BOUND REGIME (MIN monoid):
%%   δ = #inf     (default weight for unweighted assumptions)
%%   β = 0        (budget value)
%%   Mechanism: MIN(#inf) = #inf < 0, rejected by constraint/lb.lp
%%
%% CURRENT IMPLEMENTATION: δ = #sup (see line below)

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: SUPREMUM
%% ========================================
%%
%% Unweighted atoms receive #sup (NOT the semiring identity K!)
%% This is a WABA design choice for ABA recovery.

%% Assumptions with explicit weights
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W), not head(_,X).

%% Assumptions without explicit weights: Use #sup
supported_with_weight(X,W) :-
    assumption(X),
    in(X),
    not weight(X,_),
    not head(_,X),
    default_assumption_weight(W).

default_weight_is_sup :- default_assumption_weight(#sup).
finite_default_weight(V) :- default_assumption_weight(V), V != #sup, V != #inf.

%% Step 1: Compute weight for each rule derivation using conjunction (Łukasiewicz AND)
%% Łukasiewicz AND: max(0, sum(weights) - K*(n-1))
%% OPTIMIZED: Inline count and sum directly in the rule

%% Helper: detect if any body element has #sup weight (NECESSARY - kept from original)
body_has_sup_weight(R) :- body(R,B), supported_with_weight(B,#sup).

%% If any body has #sup, result is #sup (infinite truth propagates)
rule_derivation_weight(R,X,#sup) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    body_has_sup_weight(R).

%% Otherwise, apply Łukasiewicz conjunction formula directly
%% OPTIMIZED: Inline both count and sum operations
rule_derivation_weight(R,X,W) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    not body_has_sup_weight(R),
    N = #count{ B : body(R,B) },
    S = #sum{ V,B : body(R,B), supported_with_weight(B,V) },
    W = #max{ 0; S - luk_k*(N-1) }.

%% Handle rules with empty bodies (facts): Use 0 (additive identity)
rule_derivation_weight(R,X,0) :-
    head(R,X),
    supported(X),
    not body(R,_).

%% Step 2: Combine multiple derivations using disjunction (Łukasiewicz OR)
%% Łukasiewicz OR: min(K, sum)
%% IMPORTANT: Handle #sup separately (cannot be summed)

%% ======================================
%% REGULAR DERIVED ATOMS (not assumptions)
%% ======================================

%% If any derivation has #sup, result is #sup
supported_with_weight(X,#sup) :-
    supported(X),
    head(_,X),
    not assumption(X),
    rule_derivation_weight(_,X,#sup).

%% If explicit weight is #sup, result is #sup
supported_with_weight(X,#sup) :-
    supported(X),
    head(_,X),
    not assumption(X),
    weight(X,#sup).

%% Otherwise, sum finite values and cap at K
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),
    not assumption(X),
    not rule_derivation_weight(_,X,#sup),
    not weight(X,#sup),
    S = #sum{ V : rule_derivation_weight(_,X,V) ;
              V : weight(X,V) },
    W = #min{ luk_k; S }.

%% =====================================================
%% NON-FLAT-WABA: Derived assumption WITH explicit weight
%% =====================================================

%% If any derivation has #sup, result is #sup
supported_with_weight(X,#sup) :-
    assumption(X),
    supported(X),
    head(_,X),
    weight(X,_),
    rule_derivation_weight(_,X,#sup).

%% If explicit weight is #sup, result is #sup
supported_with_weight(X,#sup) :-
    assumption(X),
    supported(X),
    head(_,X),
    weight(X,#sup).

%% Otherwise, sum finite values and cap at K
supported_with_weight(X,W) :-
    assumption(X),
    supported(X),
    head(_,X),
    weight(X,_),
    not rule_derivation_weight(_,X,#sup),
    not weight(X,#sup),
    S = #sum{ V : rule_derivation_weight(_,X,V) ;
              V : weight(X,V) },
    W = #min{ luk_k; S }.

%% ================================================================
%% NON-FLAT-WABA: Derived assumption WITHOUT explicit weight, but IN
%% ================================================================

%% If any derivation has #sup, result is #sup
supported_with_weight(X,#sup) :-
    assumption(X),
    in(X),
    supported(X),
    head(_,X),
    not weight(X,_),
    rule_derivation_weight(_,X,#sup).

%% Default weight #sup always applies for unweighted assumptions
supported_with_weight(X,#sup) :-
    assumption(X),
    in(X),
    supported(X),
    head(_,X),
    not weight(X,_),
    default_weight_is_sup.

supported_with_weight(X,W) :-
    assumption(X),
    in(X),
    supported(X),
    head(_,X),
    not weight(X,_),
    not rule_derivation_weight(_,X,#sup),
    finite_default_weight(D),
    S = #sum{ V : rule_derivation_weight(_,X,V) ;
              D : true },
    W = #min{ luk_k; S }.

%% ========================================================================
%% UNDEFEATED WEIGHT COMPUTATION (for Budget-Aware Admissibility Defense)
%% ========================================================================
%% Simplified version using min (conservative estimate, matches Godel)

undefeated_weight(X,W) :- assumption(X), not defeated(X), not weight(X,_), default_assumption_weight(W).
undefeated_weight(X,W) :- assumption(X), not defeated(X), weight(X,W).
undefeated_weight(X,W) :-
    derived_from_undefeated(X),
    head(R,X),
    W = #min{ V,B : body(R,B), undefeated_weight(B,V) }.

%% Polarity: Strength (higher is better)
%% Classical ABA: beta=#sup (can't meet threshold) or beta=0 (backward compatibility)
unaffordable_attack(W,B) :- undefeated_weight(_,W), budget(B), B = #sup, W != #sup.
unaffordable_attack(W,B) :- undefeated_weight(_,W), budget(B), B = 0, W != #inf.
unaffordable_attack(W,B) :- undefeated_weight(_,W), budget(B), B != #sup, B != 0, W < B.
