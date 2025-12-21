%% Arctic (Max-Plus) Semiring for Weight Propagation
%% Semiring: (ℤ ∪ {±∞}, max, +, #inf, 0)
%% - Domain: ℤ ∪ {±∞} (integers plus positive/negative infinity)
%% - Disjunction/⊕ (OR): max (strongest alternative)
%% - Conjunction/⊗ (AND): + (accumulate rewards)
%% - Additive identity: #inf (identity for max operation)
%% - Multiplicative identity: 0 (identity for + operation)
%% - Interpretation: weights are rewards/benefits, higher is better
%%
%% SEMANTICS: Reward Accumulation / Longest Path
%% ==============================================
%% The Arctic semiring is the DUAL of the Tropical semiring:
%% - Tropical: (+, min) for cost minimization / shortest path
%% - Arctic: (+, max) for reward maximization / longest path
%%
%% Key applications:
%% - Scoring arguments by accumulated support/evidence
%% - Finding strongest evidence chains (sum of supporting weights)
%% - Benefit/reward optimization (opposite of cost minimization)
%% - Longest path problems in graphs
%%
%% Comparison to Tropical:
%% - Tropical: weights are costs (lower is better), minimize sum
%% - Arctic: weights are rewards (higher is better), maximize sum
%%
%% Note: "Arctic" comes from tropical algebra (hot=min, cold=max)

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: NEUTRALITY
%% ========================================
%%
%% Unweighted atoms receive the MULTIPLICATIVE IDENTITY (0):
%% - For addition: 0 + x = x (neutral, doesn't affect accumulation)
%% - Default weight of 0 means "no reward contributed"
%%
%% IMPORTANT: This differs from Tropical semiring!
%% - Tropical uses #sup as default (infinitely expensive to discard)
%% - Arctic uses 0 as default (neutral contribution, easily discarded)
%%
%% For Arctic semiring:
%% - Multiplicative identity = 0 (neutral for addition)
%% - Meaning: Unweighted assumptions contribute zero reward
%% - Discard cost with max monoid: max(0, ...) = other weights (not dominating)
%% - Discard cost with sum monoid: sum + 0 = sum (neutral)
%%
%% This creates different semantics than Tropical:
%% - Tropical: Unweighted assumptions are "hard to discard" (#sup)
%% - Arctic: Unweighted assumptions are "neutral" (0 reward)
%%
%% If you want unweighted assumptions to be "hard to discard" in Arctic,
%% the monoid should assign #sup as default (monoid/*.lp files handle this).

%% Assumptions with explicit weights
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W).

%% Assumptions without explicit weights: Use multiplicative identity (0)
%% For Arctic semiring, unweighted assumptions get 0 (neutral reward)
%% Rationale: Neutral contribution to reward accumulation
%% - In conjunction (+): 0 + x = x (doesn't affect sum)
%% - In disjunction (max): max(0, x) = x for x > 0 (neutral for positive rewards)
%%
%% NOTE: This is the MULTIPLICATIVE identity (neutral for conjunction).
%% For "hard to discard" semantics, monoids assign #sup as default weight.
supported_with_weight(X,0) :- assumption(X), in(X), not weight(X,_).

%% Step 1: Compute weight for each rule derivation using conjunction (addition)
%% For rule R deriving X: sum weights of all body elements (accumulate rewards)
%% IMPORTANT: Only compute weight for TRIGGERED rules (all body elements supported)

%% Special handling for #sup and #inf: clingo's #sum aggregate has limitations
%% - #sum ignores #sup values (with warning)
%% - #inf is handled correctly
%% We detect infinite values before aggregation to preserve them

%% Helper: detect if any body element has #sup weight (infinite reward)
body_has_sup_weight(R) :- body(R,B), supported_with_weight(B,#sup).

%% Helper: detect if any body element has #inf weight (infinitely negative)
body_has_inf_weight(R) :- body(R,B), supported_with_weight(B,#inf).

%% If any body has #sup, derivation weight is #sup (infinite reward propagates)
rule_derivation_weight(R,X,#sup) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    body_has_sup_weight(R).

%% If any body has #inf (and no #sup), derivation weight is #inf
rule_derivation_weight(R,X,#inf) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    not body_has_sup_weight(R),
    body_has_inf_weight(R).

%% Otherwise, sum finite weights (standard case)
rule_derivation_weight(R,X,W) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    not body_has_sup_weight(R),
    not body_has_inf_weight(R),
    W = #sum{ V,B : body(R,B), supported_with_weight(B,V) }.

%% Handle rules with empty bodies (facts): Use #inf (additive identity for max)
%% IMPORTANT: Use #inf (not 0) to make empty-body derivations "invisible" in max
%%
%% Rationale:
%% - Facts derive conclusions without premises
%% - In disjunction (max), we want explicit weights to dominate
%% - max(#inf, explicit_weight) = explicit_weight ✓
%% - If we used 0: max(0, negative_weight) = 0 ✗ (wrong!)
%%
%% Algebraic justification:
%% - #inf is the true additive identity for max: max(x, #inf) = x
%% - Empty-body derivations contribute no information
%% - Explicit weights take precedence
rule_derivation_weight(R,X,#inf) :-
    head(R,X),
    supported(X),
    not body(R,_).

%% Step 2: Combine multiple derivations using disjunction (maximum)
%% The weight of X is the maximum across all its rule derivations
%% AND any explicit weight (OR semantics: explicit weight is another "derivation")
%% Interpretation: Multiple derivation paths → take strongest/highest reward path
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),  % X is derived (not just an assumption)
    W = #max{ V : rule_derivation_weight(_,X,V) ;
              V : weight(X,V) }.
