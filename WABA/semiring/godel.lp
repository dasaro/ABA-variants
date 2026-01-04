%% Gödel Semiring for Weight Propagation (Fuzzy Logic) - GROUNDING OPTIMIZED
%% Semiring: (ℤ ∪ {±∞}, max, min, #inf, #sup)
%% - Domain: All integers plus infinities
%% - Disjunction/⊕ (OR, multiple derivations): max (strongest alternative)
%% - Conjunction/⊗ (AND, body elements): min (weakest link)
%% - Additive identity: #inf (identity for max operation)
%% - Multiplicative identity: #sup (identity for min operation)
%% - Interpretation: weights are truth degrees, higher is better
%%
%% OPTIMIZATIONS APPLIED:
%% - Use not is_head(X) instead of not head(_,X)
%% - Use not has_body(R) instead of not body(R,_)
%% - Use rule(R) consistently for rule domains
%% - Remove redundant supported(X) checks
%%
%% In Gödel fuzzy logic:
%% - Domain: ℤ ∪ {±∞} (integers plus positive/negative infinity)
%% - Conjunction takes the minimum (weakest link in a chain)
%% - Disjunction takes the maximum (strongest of multiple proofs)
%% - Unweighted atoms get #sup (maximum truth, hardest to discard)

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
%%              (line 41: `:- discarded_attack(_,_,#sup), budget(B), B != #sup.`)
%%
%% LOWER BOUND REGIME (MIN monoid):
%%   Option 1 (recommended):
%%     δ = #inf   (default weight)
%%     β = 0      (budget value)
%%     Mechanism: MIN(#inf) = #inf < 0, rejected by constraint/lb.lp
%%   Option 2:
%%     δ = #sup   (default weight)
%%     β = any    (any finite budget)
%%     Mechanism: constraint/lb.lp explicitly rejects discarding #sup attacks
%%                (line 43: `:- discarded_attack(_,_,#sup).`)
%%
%% CURRENT IMPLEMENTATION: δ = #sup (see line ~45 below)
%% This enables ABA recovery for all monoids with appropriate budget settings.

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
%% FLAT-WABA: assumption is not a rule head
%% NON-FLAT-WABA: if assumption is also a rule head, weight is computed below via rule derivation
%% OPTIMIZED: Use not is_head(X) instead of not head(_,X)
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W), not is_head(X).

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
%%
%% FLAT-WABA: assumption is not a rule head
%% NON-FLAT-WABA: if assumption is also a rule head, weight is computed below via rule derivation
%% OPTIMIZED: Use not is_head(X) instead of not head(_,X)
supported_with_weight(X,#sup) :- assumption(X), in(X), not weight(X,_), not is_head(X).

%% Step 1: Compute weight for each rule derivation using conjunction (minimum)
%% For rule R deriving X: take minimum weight among all body elements
%% IMPORTANT: Only compute weight for TRIGGERED rules (all body elements supported)
%% OPTIMIZED: Use rule(R) instead of head(R,X), remove redundant supported(X) check
rule_derivation_weight(R,X,W) :-
    rule(R),
    head(R,X),
    has_body(R),  % Only for rules with bodies
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
%% OPTIMIZED: Use not has_body(R) instead of not body(R,_), use rule(R)
rule_derivation_weight(R,X,#inf) :-
    rule(R),
    head(R,X),
    not has_body(R).

%% Step 2: Combine multiple derivations using disjunction (maximum)
%% IMPORTANT: Use DISJUNCTION OPERATOR (⊕) to combine weights from different paths:
%% - Multiple rule derivations are combined via ⊕
%% - Explicit weight is another "path" to support, combined via ⊕
%% - For Gödel semiring: ⊕ = max (choose strongest/highest truth path)
%%
%% SEMANTICS: Explicit weight + derived weight represent ALTERNATIVE support paths.
%% The actual weight is their DISJUNCTION, not conjunction or override.
%%
%% Example: If X has explicit weight 50 and is also derived with weight 80,
%%          then supported_with_weight(X, max(50, 80)) = supported_with_weight(X, 80)
%%          (the stronger path is chosen)
%% OPTIMIZED: Use derived_atom(X) instead of head(_,X), not assumption(X)
supported_with_weight(X,W) :-
    derived_atom(X),
    supported(X),
    W = #max{ V,R : rule_derivation_weight(R,X,V) ;
              V : weight(X,V) }.  % DISJUNCTION (⊕ = max for Gödel)

%% NON-FLAT-WABA: Derived assumption with explicit weight
%% Combine rule-derived weight with explicit weight via DISJUNCTION (max)
%% OPTIMIZED: Use is_head(X) instead of head(_,X)
supported_with_weight(X,W) :-
    assumption(X),
    supported(X),
    is_head(X),  % Assumption is also derived
    weight(X,_),  % Has explicit weight
    W = #max{ V,R : rule_derivation_weight(R,X,V) ;
              V : weight(X,V) }.  % DISJUNCTION (⊕ = max for Gödel)

%% NON-FLAT-WABA: Derived assumption WITHOUT explicit weight, but is IN
%% For Gödel: max(derived, #sup) = #sup always (default dominates)
%% NOTE: Clingo ignores #sup in aggregates, so we assign it explicitly
%% OPTIMIZED: Use is_head(X) instead of head(_,X)
supported_with_weight(X,#sup) :-
    assumption(X),
    in(X),  % Assumption is selected
    supported(X),
    is_head(X),  % Assumption is also derived
    not weight(X,_).  % No explicit weight → default #sup dominates

undefeated_weight(X,#sup) :- assumption(X), not defeated(X).
undefeated_weight(X,W) :- derived_from_undefeated(X), weight(X,W).
undefeated_weight(X,W) :- derived_from_undefeated(X), head(R,X), W = #min{ V,B : body(R,B), undefeated_weight(B,V) }.
%% Polarity: Strength (higher is better)
unaffordable_attack(W,B) :- undefeated_weight(_,W), budget(B), W < B.
