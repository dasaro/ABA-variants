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
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W).

%% Assumptions without explicit weights: Use multiplicative identity (#inf)
%% For Bottleneck-cost semiring, unweighted assumptions get #inf (zero cost)
%% Rationale: Neutral contribution to bottleneck cost
%% - In conjunction (max): max(#inf, x) = x (doesn't affect bottleneck)
%% - In disjunction (min): min(#inf, x) = #inf (infinitely cheap)
%%
%% NOTE: This is the MULTIPLICATIVE identity (neutral for conjunction).
%% For "hard to discard" semantics, monoids assign #sup as default weight.
supported_with_weight(X,#inf) :- assumption(X), in(X), not weight(X,_).

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
%% The weight of X is the MINIMUM across all its rule derivations
%% AND any explicit weight (OR semantics: explicit weight is another "derivation")
%% Interpretation: Multiple derivation paths → take cheapest/lowest-cost path
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),  % X is derived (not just an assumption)
    W = #min{ V : rule_derivation_weight(_,X,V) ;
              V : weight(X,V) }.
