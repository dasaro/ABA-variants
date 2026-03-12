%% Tropical Semiring for Weight Propagation
%% Semiring: (ℤ ∪ {±∞}, min, +, #sup, 0)
%% - Domain: All integers plus infinities
%% - Disjunction/⊕ (OR, multiple derivations): min (choose best path)
%% - Conjunction/⊗ (AND, body elements): + (accumulate costs)
%% - Additive identity: #sup (identity for min operation)
%% - Multiplicative identity: 0 (identity for addition)
%% - Interpretation: weights are costs, lower is better
%%
%% This is the tropical semiring used for shortest path problems.

active_semiring(tropical).
#include "../defaults/base.lp".

semiring_default_weight(legacy,#sup).
semiring_default_weight(aba,#sup).
semiring_default_weight(neutral,0).

%% =============================================
%% CLASSICAL ABA RECOVERY (No Discarding)
%% =============================================
%%
%% To recover plain unweighted ABA behavior with this semiring:
%%
%% UPPER BOUND REGIME (MAX, SUM, COUNT, LEX monoids):
%%   δ = #sup     (default weight for unweighted assumptions)
%%   β = 0        (budget value)
%%   Mechanism: constraint/ub.lp explicitly rejects discarding #sup-weighted attacks
%%
%% LOWER BOUND REGIME (MIN monoid):
%%   δ = #inf     (default weight for unweighted assumptions)
%%   β = 0        (budget value)
%%   Mechanism: MIN(#inf) = #inf < 0, rejected by constraint/lb.lp
%%   Alternative: δ = #sup with special constraint rejection
%%
%% CURRENT IMPLEMENTATION: δ = #sup (see line ~52 below)
%% This enables ABA recovery for UB monoids with β = 0.
%% For LB monoids, use δ = #inf by setting all assumption weights explicitly.

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: SUPREMUM
%% ========================================
%%
%% Unweighted atoms receive the SUPREMUM (maximum value in range):
%% - Matches standard ABA: assumptions accepted by default ("innocent until proven guilty")
%% - "Hardest to discard": attacks from unweighted atoms are maximally expensive
%% - Budget semantics: attacks with cost #sup (∞) CANNOT be discarded
%%
%% For Tropical:
%% - Supremum = #sup (∞, infinite cost)
%% - Meaning: Unweighted assumptions have infinite cost (unbounded)
%% - Discard cost with max monoid: max(#sup, ...) = #sup (impossible to discard!)
%% - Discard cost with min monoid: min(#sup, ...) = other values (doesn't contribute)
%% - Discard cost with sum monoid: sum + #sup = #sup (impossible to discard!)
%%
%% Note: This makes unweighted attacks IMPOSSIBLE to discard (not just expensive).
%% Only attacks with explicit finite costs can be discarded within budget constraints.
%%
%% Explicit weights REPLACE the supremum default (via mutually exclusive rules).
%% DEFAULT WEIGHTS for unweighted atoms are now defined in monoid/*.lp files,
%% since the monoid determines what "hard to discard" means.
%%

%% Assumptions with explicit weights
%% FLAT-WABA: assumption is not a rule head
%% NON-FLAT-WABA: if assumption is also a rule head, weight is computed below via rule derivation
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W), not head(_,X).

%% Assumptions without explicit weights: Use supremum (infinite cost)
%% For Tropical semiring, unweighted assumptions get #sup (infinite cost)
%% Rationale: Unweighted assumptions are "hardest to discard" (default acceptance)
%% - #sup = positive infinity (infinite cost)
%% - Matches standard ABA: assumptions accepted by default
%% - In conjunction (+): #sup + x = #sup (infinite cost propagates)
%% - In disjunction (min): min(#sup, x) = x (doesn't dominate)
%%
%% NOTE: Uses #sup (positive infinity) as supremum.
%% Constraints must handle #sup specially for budget checking.
%%
%% FLAT-WABA: assumption is not a rule head
%% NON-FLAT-WABA: if assumption is also a rule head, weight is computed below via rule derivation
supported_with_weight(X,W) :-
    assumption(X),
    in(X),
    not weight(X,_),
    not head(_,X),
    default_assumption_weight(W).

%% Step 1: Compute weight for each rule derivation using conjunction (addition)
%% For rule R deriving X: sum the weights of all body elements
%% IMPORTANT: Only compute weight for TRIGGERED rules (all body elements supported)
%%
%% Special handling for #sup: clingo's #sum aggregate ignores #sup values
%% If ANY body element has weight #sup, result is #sup (infinite cost propagates)

%% Helper: detect if any body element has #sup weight
body_has_sup_weight(R) :- body(R,B), supported_with_weight(B,#sup).

%% If any body has #sup, derivation weight is #sup (infinite cost)
rule_derivation_weight(R,X,#sup) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    body_has_sup_weight(R).

%% Otherwise, sum finite weights (no #sup values present)
rule_derivation_weight(R,X,W) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    not body_has_sup_weight(R),
    W = #sum{ V,B : body(R,B), supported_with_weight(B,V) }.

%% Handle rules with empty bodies (facts): Use #sup (identity for min)
%% SOLUTION: Use additive identity (#sup for min) instead of multiplicative identity (0 for +)
%%
%% Traditional approach assigned 0 (multiplicative identity for +/conjunction):
%%   rule_derivation_weight(R,X,0) :- ... not body(R,_).
%%
%% Problem: min(0, explicit_weight) = 0 dominates all explicit weights > 0!
%%   Example: weight(c1, 8) → min(0, 8) = 0 → explicit weight LOST
%%
%% Solution: Use #sup (additive identity for min/disjunction):
%%   min(#sup, x) = x for any x < #sup
%%   This makes empty-body derivations "invisible" in the min aggregate
%%   Explicit weights are preserved: min(#sup, 8) = 8 ✓
%%
%% Algebraic justification:
%%   - #sup is the true identity for min operation (a ⊕ #sup = a)
%%   - Empty-body facts contribute no information to weight disjunction
%%   - Explicit weights take precedence without special-case logic
%%
rule_derivation_weight(R,X,#sup) :-
    head(R,X),
    supported(X),
    not body(R,_).

%% Step 2: Combine multiple derivations using disjunction (minimum)
%% IMPORTANT: Use DISJUNCTION OPERATOR (⊕) to combine weights from different paths:
%% - Multiple rule derivations are combined via ⊕
%% - Explicit weight is another "path" to support, combined via ⊕
%% - For Tropical semiring: ⊕ = min (choose best/cheapest path)
%%
%% SEMANTICS: Explicit weight + derived weight represent ALTERNATIVE support paths.
%% The actual weight is their DISJUNCTION, not conjunction or override.
%%
%% Example: If X has explicit weight 50 and is also derived with weight 30,
%%          then supported_with_weight(X, min(50, 30)) = supported_with_weight(X, 30)
%%          (the cheaper path is chosen)
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),  % X is derived (not just an assumption)
    not assumption(X),  % X is not an assumption
    W = #min{ V,R : rule_derivation_weight(R,X,V) ;
              V : weight(X,V) }.  % DISJUNCTION (⊕ = min for Tropical)

%% NON-FLAT-WABA: Derived assumption with explicit weight
%% Combine rule-derived weight with explicit weight via DISJUNCTION (min)
supported_with_weight(X,W) :-
    assumption(X),
    supported(X),
    head(_,X),  % Assumption is also derived
    weight(X,_),  % Has explicit weight
    W = #min{ V,R : rule_derivation_weight(R,X,V) ;
              V : weight(X,V) }.  % DISJUNCTION (⊕ = min for Tropical)

%% NON-FLAT-WABA: Derived assumption WITHOUT explicit weight, but is IN
%% Combine rule-derived weight with default assumption weight (#sup) via DISJUNCTION (min)
supported_with_weight(X,W) :-
    assumption(X),
    in(X),  % Assumption is selected
    supported(X),
    head(_,X),  % Assumption is also derived
    not weight(X,_),  % No explicit weight
    default_assumption_weight(D),
    W = #min{ V,R : rule_derivation_weight(R,X,V) ;
              D : true }.  % Direct assumption path selected by the active default policy

%% ========================================================================
%% UNDEFEATED WEIGHT COMPUTATION (for Budget-Aware Admissibility Defense)
%% ========================================================================
%%
%% Mirrors supported_with_weight logic but for derived_from_undefeated elements.
%% Used to compute potential attack weights for defense checking.

%% Base case: Undefeated assumptions without explicit weights get #sup
undefeated_weight(X,W) :-
    assumption(X),
    not defeated(X),
    not weight(X,_),
    not head(_,X),
    default_assumption_weight(W).

%% FLAT-WABA: Undefeated assumptions with explicit weights (not rule heads)
undefeated_weight(X,W) :- assumption(X), not defeated(X), weight(X,W), not head(_,X).

%% Helper: detect if any body element has #sup weight in undefeated derivation
undefeated_body_has_sup(R) :- body(R,B), undefeated_weight(B,#sup).

%% Rule derivation weight for undefeated: sum body weights (with #sup propagation)
undefeated_rule_weight(R,X,#sup) :-
    head(R,X),
    derived_from_undefeated(X),
    body(R,_),
    triggered_by_undefeated(R),
    undefeated_body_has_sup(R).

undefeated_rule_weight(R,X,W) :-
    head(R,X),
    derived_from_undefeated(X),
    body(R,_),
    triggered_by_undefeated(R),
    not undefeated_body_has_sup(R),
    W = #sum{ V,B : body(R,B), undefeated_weight(B,V), V != #sup }.

%% Regular derived element: take minimum across all derivations (disjunction)
undefeated_weight(X,W) :-
    derived_from_undefeated(X),
    head(_,X),
    not assumption(X),
    W = #min{ V,R : undefeated_rule_weight(R,X,V) }.

%% NON-FLAT-WABA: Assumption that is also a rule head, WITH explicit weight
undefeated_weight(X,W) :-
    assumption(X),
    not defeated(X),
    derived_from_undefeated(X),
    head(_,X),
    weight(X,_),
    W = #min{ V,R : undefeated_rule_weight(R,X,V) ;
              V : weight(X,V) }.

%% NON-FLAT-WABA: Assumption that is also a rule head, WITHOUT explicit weight
undefeated_weight(X,W) :-
    assumption(X),
    not defeated(X),
    derived_from_undefeated(X),
    head(_,X),
    not weight(X,_),
    default_assumption_weight(D),
    W = #min{ V,R : undefeated_rule_weight(R,X,V) ;
              D : true }.

%% Polarity: Cost (lower is better)
%% Special case: beta=0 means classical ABA (all attacks unaffordable)
unaffordable_attack(W,B) :- undefeated_weight(_,W), budget(B), B = 0, W != #inf.
unaffordable_attack(W,B) :- undefeated_weight(_,W), budget(B), B != 0, W > B.
