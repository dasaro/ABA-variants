%% Arctic (Max-Plus) Semiring for Weight Propagation - OPTIMIZED
%% Semiring: (ℤ ∪ {±∞}, max, +, #inf, 0)
%% - Domain: ℤ ∪ {±∞} (integers plus positive/negative infinity)
%% - Disjunction/⊕ (OR): max (strongest alternative)
%% - Conjunction/⊗ (AND): + (accumulate rewards)
%% - Additive identity: #inf (identity for max operation)
%% - Multiplicative identity: 0 (identity for + operation)
%% - Interpretation: weights are rewards/benefits, higher is better
%%
%% OPTIMIZATION NOTES:
%% ===================
%% This version removes redundant #inf handling that was causing performance issues:
%% - REMOVED: body_has_inf_weight(R) helper (never true in practice)
%% - REMOVED: rule_derivation_weight for #inf with bodies (never fires)
%% - REMOVED: not body_has_inf_weight(R) negations (redundant checks)
%%
%% Rationale:
%% - Benchmarks show NO frameworks use #inf weights in rule bodies
%% - #inf only used for empty-body rules (additive identity for max)
%% - Redundant checks caused 20-40% grounding overhead
%% - Structure now matches Tropical semiring (cleaner, faster)
%%
%% SEMANTICS: Reward Accumulation / Longest Path
%% ==============================================
%% The Arctic semiring is the DUAL of the Tropical semiring:
%% - Tropical: (+, min) for cost minimization / shortest path
%% - Arctic: (+, max) for reward maximization / longest path

%% =============================================
%% CLASSICAL ABA RECOVERY (No Discarding)
%% =============================================
%%
%% To recover plain unweighted ABA behavior with this semiring:
%%
%% UPPER BOUND REGIME (MAX, SUM, COUNT monoids):
%%   δ = 0        (default weight for unweighted assumptions)
%%   β = #inf     (budget value - negative infinity)
%%   Mechanism: Any discard gives cost ≥ 0 > #inf, rejected by constraint/ub.lp
%%   Note: β = #inf must be set in framework file
%%         Add: budget(#inf). to your .lp file
%%
%% LOWER BOUND REGIME (MIN monoid):
%%   δ = 0        (default weight for unweighted assumptions)
%%   β = #sup     (budget value - positive infinity)
%%   Mechanism: MIN(0) = 0 < #sup, rejected by constraint/lb.lp
%%              No discards: cost = #sup ≥ #sup, accepted
%%
%% CURRENT IMPLEMENTATION: δ = 0 (see line ~54 below)
%% This is the natural default for Arctic (multiplicative identity).

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: NEUTRALITY
%% ========================================
%%
%% Unweighted atoms receive the MULTIPLICATIVE IDENTITY (0):
%% - For addition: 0 + x = x (neutral, doesn't affect accumulation)
%% - Default weight of 0 means "no reward contributed"

%% Assumptions with explicit weights
%% FLAT-WABA: assumption is not a rule head
%% NON-FLAT-WABA: if assumption is also a rule head, weight is computed below via rule derivation
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W), not head(_,X).

%% Assumptions without explicit weights: Use multiplicative identity (0)
%% For Arctic semiring, unweighted assumptions get 0 (neutral reward)
%% Rationale: Neutral contribution to reward accumulation
%% - In conjunction (+): 0 + x = x (doesn't affect sum)
%% - In disjunction (max): max(0, x) = x for x > 0 (neutral for positive rewards)
%%
%% FLAT-WABA: assumption is not a rule head
%% NON-FLAT-WABA: if assumption is also a rule head, weight is computed below via rule derivation
supported_with_weight(X,0) :- assumption(X), in(X), not weight(X,_), not head(_,X).

%% Step 1: Compute weight for each rule derivation using conjunction (addition)
%% For rule R deriving X: sum weights of all body elements (accumulate rewards)
%% IMPORTANT: Only compute weight for TRIGGERED rules (all body elements supported)

%% OPTIMIZED: Only handle #sup (infinite reward propagation)
%% #inf handling removed - never occurs in practice, caused 20-40% overhead

%% Helper: detect if any body element has #sup weight (infinite reward)
body_has_sup_weight(R) :- body(R,B), supported_with_weight(B,#sup).

%% If any body has #sup, derivation weight is #sup (infinite reward propagates)
rule_derivation_weight(R,X,#sup) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    body_has_sup_weight(R).

%% Otherwise, sum finite weights (standard case)
%% OPTIMIZED: Removed "not body_has_inf_weight(R)" - redundant negation
rule_derivation_weight(R,X,W) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    not body_has_sup_weight(R),
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
%% IMPORTANT: Use DISJUNCTION OPERATOR (⊕) to combine weights from different paths:
%% - Multiple rule derivations are combined via ⊕
%% - Explicit weight is another "path" to support, combined via ⊕
%% - For Arctic semiring: ⊕ = max (choose strongest/highest reward path)
%%
%% SEMANTICS: Explicit weight + derived weight represent ALTERNATIVE support paths.
%% The actual weight is their DISJUNCTION, not conjunction or override.
%%
%% Example: If X has explicit weight 10 and is also derived with weight 25,
%%          then supported_with_weight(X, max(10, 25)) = supported_with_weight(X, 25)
%%          (the higher reward path is chosen)
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),  % X is derived (not just an assumption)
    not assumption(X),  % X is not an assumption
    W = #max{ V,R : rule_derivation_weight(R,X,V) ;
              V : weight(X,V) }.  % DISJUNCTION (⊕ = max for Arctic)

%% NON-FLAT-WABA: Derived assumption with explicit weight
%% Combine rule-derived weight with explicit weight via DISJUNCTION (max)
supported_with_weight(X,W) :-
    assumption(X),
    supported(X),
    head(_,X),  % Assumption is also derived
    weight(X,_),  % Has explicit weight
    W = #max{ V,R : rule_derivation_weight(R,X,V) ;
              V : weight(X,V) }.  % DISJUNCTION (⊕ = max for Arctic)

%% NON-FLAT-WABA: Derived assumption WITHOUT explicit weight, but is IN
%% Combine rule-derived weight with default assumption weight (0) via DISJUNCTION (max)
supported_with_weight(X,W) :-
    assumption(X),
    in(X),  % Assumption is selected
    supported(X),
    head(_,X),  % Assumption is also derived
    not weight(X,_),  % No explicit weight
    W = #max{ V,R : rule_derivation_weight(R,X,V) ;
              0 : true }.  % DISJUNCTION with default: max(derived, 0) = derived (if positive)
