%% Gödel Semiring for Weight Propagation (Fuzzy Logic)
%% Semiring: (ℤ ∪ {±∞}, max, min, #inf, #sup)
%% - Domain: All integers plus infinities
%% - Disjunction/⊕ (OR, multiple derivations): max (strongest alternative)
%% - Conjunction/⊗ (AND, body elements): min (weakest link)
%% - Additive identity: #inf (identity for max operation)
%% - Multiplicative identity: #sup (identity for min operation)
%% - Interpretation: weights are truth degrees, higher is better
%%
%% In Gödel fuzzy logic:
%% - Domain: ℤ ∪ {±∞} (integers plus positive/negative infinity)
%% - Conjunction takes the minimum (weakest link in a chain)
%% - Disjunction takes the maximum (strongest of multiple proofs)
%% - Unweighted atoms get #sup (maximum truth, hardest to discard)

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: SUPREMUM
%% ========================================
%%
%% Unweighted atoms receive the SUPREMUM (maximum value in range):
%% - Matches standard ABA: assumptions accepted by default ("innocent until proven guilty")
%% - "Hardest to discard": attacks from unweighted atoms are maximally expensive
%% - Budget semantics: requires budget ≥ #sup to discard such attacks
%%
%% For Gödel semiring:
%% - Supremum = #sup (positive infinity, fully true, maximum truth degree)
%% - Meaning: Unweighted assumptions have maximum truth value
%% - Discard cost with max monoid: max(#sup, ...) = #sup (infinitely expensive)
%% - Discard cost with min monoid: not compatible (see compatibility theory)
%% - Discard cost with sum monoid: sum += #sup → #sup (infinitely expensive)
%%
%% Explicit weights REPLACE the supremum default (via mutually exclusive rules).
%% DEFAULT WEIGHTS for unweighted atoms are now defined in monoid/*.lp files,
%% since the monoid determines what "hard to discard" means.
%%

%% Assumptions with explicit weights
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W).

%% Assumptions without explicit weights: Use supremum (maximum truth value)
%% For Gödel semiring, unweighted assumptions get #sup (maximum truth degree)
%% Rationale: Unweighted assumptions are "hardest to discard" (default acceptance)
%% - Matches standard ABA semantics: assumptions accepted by default
%% - #sup = positive infinity (supremum, maximum value)
%% - In conjunction (min): min(#sup, x) = x (doesn't affect derivations)
%% - In disjunction (max): max(#sup, x) = #sup (dominates, represents maximum truth)
%%
%% NOTE: Uses #sup (positive infinity) as the supremum value.
%% Constraints must handle #sup specially for budget checking.
supported_with_weight(X,#sup) :- assumption(X), in(X), not weight(X,_).

%% Step 1: Compute weight for each rule derivation using conjunction (minimum)
%% For rule R deriving X: take minimum weight among all body elements
%% IMPORTANT: Only compute weight for TRIGGERED rules (all body elements supported)
rule_derivation_weight(R,X,W) :-
    head(R,X),
    supported(X),
    body(R,_),  % Only for rules with bodies
    triggered_by_in(R),  % Only triggered rules (prevents #sup from unsupported bodies)
    W = #min{ V,B : body(R,B), supported_with_weight(B,V) }.

%% Handle rules with empty bodies (facts): Use #inf (identity for max)
%% SOLUTION: Use additive identity (#inf for max) instead of multiplicative identity (#sup for min)
%%
%% Traditional approach assigned #sup (multiplicative identity for min/conjunction):
%%   rule_derivation_weight(R,X,#sup) :- ... not body(R,_).
%%
%% Problem: max(#sup, explicit_weight) = #sup dominates all explicit weights!
%%   Example: weight(c1, 8) → max(#sup, 8) = #sup → explicit weight LOST
%%
%% Solution: Use #inf (additive identity for max/disjunction):
%%   max(#inf, x) = x for any x > #inf
%%   This makes empty-body derivations "invisible" in the max aggregate
%%   Explicit weights are preserved: max(#inf, 8) = 8 ✓
%%
%% Algebraic justification:
%%   - #inf is the true identity for max operation (a ⊕ #inf = a)
%%   - Empty-body facts contribute no information to weight disjunction
%%   - Explicit weights take precedence without special-case logic
%%
rule_derivation_weight(R,X,#inf) :-
    head(R,X),
    supported(X),
    not body(R,_).

%% Step 2: Combine multiple derivations using disjunction (maximum)
%% The weight of X is the maximum across all its rule derivations
%% AND any explicit weight (OR semantics: explicit weight is another "derivation")
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),  % X is derived (not just an assumption)
    W = #max{ V : rule_derivation_weight(_,X,V) ;
              V : weight(X,V) }.
