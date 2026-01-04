%% Bottleneck-Cost Semiring for Weight Propagation
%% Semiring: (ℤ ∪ {±∞}, min, max, #sup, #inf)
%% - Domain: ℤ ∪ {±∞} (integers plus positive/negative infinity)
%% - Disjunction/⊕ (OR): min (cheapest alternative)
%% - Conjunction/⊗ (AND): max (bottleneck / worst component)
%% - Additive identity: #sup (identity for min operation)
%% - Multiplicative identity: #inf (identity for max operation)
%% - Interpretation: weights are costs/penalties, LOWER is better
%%
%% SEMANTICS: Bottleneck Cost / Maximum Penalty
%% ============================================
%% The bottleneck-cost semiring models scenarios where:
%% - A chain's cost is determined by its WORST/highest-cost component (max for conjunction)
%% - Among alternatives, choose the CHEAPEST path (min for disjunction)
%% - Applications: Bottleneck problems, worst-case cost, maximum penalty
%%
%% Key insight: This is the DUAL of standard min/max bottleneck:
%% - Standard bottleneck (min/max): Maximize minimum capacity
%% - Bottleneck-cost (max/min): Minimize maximum cost
%%
%% Examples:
%% - Quality control: Reject batch if ANY component exceeds defect threshold (max)
%% - Security: System vulnerability = worst component vulnerability (max)
%% - Logistics: Route cost = bottleneck (slowest/most expensive segment)

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
%% CURRENT IMPLEMENTATION: δ = #sup (see line ~60 below)
%% This enables ABA recovery for UB monoids with β = 0.
%% For LB monoids, use δ = #inf by setting all assumption weights explicitly.
%%
%% Comparison to Tropical:
%% - Tropical (+/min): Minimize SUM of costs (total cost matters)
%% - Bottleneck-cost (max/min): Minimize MAX of costs (worst-case matters)

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: INFIMUM
%% ========================================
%%
%% Unweighted atoms receive the INFIMUM (minimum value in range):
%% - For bottleneck-cost semantics: #inf = infinitely GOOD (zero cost)
%% - Meaning: Unweighted assumptions impose no cost/penalty
%%
%% IMPORTANT: This differs from Tropical and Arctic!
%% - Tropical: #sup default (infinitely expensive, hard to discard)
%% - Bottleneck-cost: #inf default (zero cost, easy to discard)
%%
%% For Bottleneck-cost semiring:
%% - Multiplicative identity = #inf (neutral for max)
%% - Meaning: Unweighted assumptions contribute zero cost
%% - In conjunction (max): max(#inf, x) = x (no cost added)
%% - In disjunction (min): min(#inf, x) = #inf (infinitely cheap path)
%%
%% This creates "optimistic" semantics:
%% - Unweighted assumptions are assumed to be "free" (zero cost)
%% - Only explicit weights impose costs
%%
%% If you want unweighted assumptions to be "hard to discard", the monoid
%% should assign #sup as default weight (monoid/*.lp files handle this).

%% Assumptions with explicit weights
%% FLAT-WABA: assumption is not a rule head
%% NON-FLAT-WABA: if assumption is also a rule head, weight is computed below via rule derivation
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W), not head(_,X).

%% Assumptions without explicit weights: Use multiplicative identity (#inf)
%% For Bottleneck-cost semiring, unweighted assumptions get #inf (zero cost)
%% Rationale: Neutral contribution to bottleneck cost
%% - In conjunction (max): max(#inf, x) = x (doesn't affect bottleneck)
%% - In disjunction (min): min(#inf, x) = #inf (infinitely cheap)
%%
%% NOTE: This is the MULTIPLICATIVE identity (neutral for conjunction).
%% For "hard to discard" semantics, monoids assign #sup as default weight.
%%
%% FLAT-WABA: assumption is not a rule head
%% NON-FLAT-WABA: if assumption is also a rule head, weight is computed below via rule derivation
supported_with_weight(X,#inf) :- assumption(X), in(X), not weight(X,_), not head(_,X).

%% Step 1: Compute weight for each rule derivation using conjunction (maximum)
%% For rule R deriving X: take MAXIMUM weight among all body elements (bottleneck)
%% Interpretation: Chain is only as good as its WORST (highest-cost) component
%% IMPORTANT: Only compute weight for TRIGGERED rules (all body elements supported)
rule_derivation_weight(R,X,W) :-
    head(R,X),
    supported(X),
    body(R,_),  % Only for rules with bodies
    triggered_by_in(R),  % Only triggered rules
    W = #max{ V,B : body(R,B), supported_with_weight(B,V) }.

%% Handle rules with empty bodies (facts): Use #sup (additive identity for min)
%% IMPORTANT: Use #sup (not #inf) to make empty-body derivations "invisible" in min
%%
%% Rationale:
%% - Facts derive conclusions without premises
%% - In disjunction (min), we want explicit weights to dominate
%% - min(#sup, explicit_weight) = explicit_weight ✓
%% - If we used #inf: min(#inf, positive_weight) = #inf ✗ (always cheapest!)
%%
%% Algebraic justification:
%% - #sup is the true additive identity for min: min(x, #sup) = x
%% - Empty-body derivations contribute no information
%% - Explicit weights take precedence
rule_derivation_weight(R,X,#sup) :-
    head(R,X),
    supported(X),
    not body(R,_).

%% Step 2: Combine multiple derivations using disjunction (minimum)
%% IMPORTANT: Use DISJUNCTION OPERATOR (⊕) to combine weights from different paths:
%% - Multiple rule derivations are combined via ⊕
%% - Explicit weight is another "path" to support, combined via ⊕
%% - For Bottleneck-cost semiring: ⊕ = min (choose cheapest/lowest-cost path)
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
              V : weight(X,V) }.  % DISJUNCTION (⊕ = min for Bottleneck-cost)

%% NON-FLAT-WABA: Derived assumption with explicit weight
%% Combine rule-derived weight with explicit weight via DISJUNCTION (min)
supported_with_weight(X,W) :-
    assumption(X),
    supported(X),
    head(_,X),  % Assumption is also derived
    weight(X,_),  % Has explicit weight
    W = #min{ V,R : rule_derivation_weight(R,X,V) ;
              V : weight(X,V) }.  % DISJUNCTION (⊕ = min for Bottleneck-cost)

%% NON-FLAT-WABA: Derived assumption WITHOUT explicit weight, but is IN
%% Combine rule-derived weight with default assumption weight (#inf) via DISJUNCTION (min)
supported_with_weight(X,W) :-
    assumption(X),
    in(X),  % Assumption is selected
    supported(X),
    head(_,X),  % Assumption is also derived
    not weight(X,_),  % No explicit weight
    W = #min{ V,R : rule_derivation_weight(R,X,V) ;
              #inf : true }.  % DISJUNCTION with default: min(derived, #inf) = derived

%% ========================================================================
%% UNDEFEATED WEIGHT COMPUTATION (for Budget-Aware Admissibility Defense)
%% ========================================================================

%% Base cases
undefeated_weight(X,#sup) :- assumption(X), not defeated(X), not weight(X,_), not head(_,X).
undefeated_weight(X,W) :- assumption(X), not defeated(X), weight(X,W), not head(_,X).

%% Rule derivation with Bottleneck conjunction (max - worst component)
undefeated_rule_weight(R,X,W) :-
    head(R,X),
    derived_from_undefeated(X),
    body(R,_),
    triggered_by_undefeated(R),
    W = #max{ V,B : body(R,B), undefeated_weight(B,V) }.

%% Disjunction (min - cheapest path)
undefeated_weight(X,W) :-
    derived_from_undefeated(X),
    head(_,X),
    not assumption(X),
    W = #min{ V,R : undefeated_rule_weight(R,X,V) }.

%% NON-FLAT: Assumptions that are also rule heads
undefeated_weight(X,W) :-
    assumption(X),
    not defeated(X),
    derived_from_undefeated(X),
    head(_,X),
    weight(X,_),
    W = #min{ V,R : undefeated_rule_weight(R,X,V) ;
              V : weight(X,V) }.

undefeated_weight(X,W) :-
    assumption(X),
    not defeated(X),
    derived_from_undefeated(X),
    head(_,X),
    not weight(X,_),
    W = #min{ V,R : undefeated_rule_weight(R,X,V) ;
              #sup : true }.

%% Polarity: Cost (lower is better)
unaffordable_attack(W,B) :- undefeated_weight(_,W), budget(B), W > B.
