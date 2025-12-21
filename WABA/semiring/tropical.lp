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
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W).

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
supported_with_weight(X,#sup) :- assumption(X), in(X), not weight(X,_).

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
%% The weight of X is the minimum across all its rule derivations
%% AND any explicit weight (OR semantics: explicit weight is another "derivation")
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),  % X is derived (not just an assumption)
    W = #min{ V : rule_derivation_weight(_,X,V) ;
              V : weight(X,V) }.
