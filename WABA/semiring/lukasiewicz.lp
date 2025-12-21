%% Łukasiewicz Semiring for Weight Propagation
%% Semiring: (ℤ ∪ {±∞}, ⊕_Ł, ⊗_Ł, #inf, #sup)
%% - Domain: ℤ ∪ {±∞} (integers plus positive/negative infinity)
%% - Disjunction/⊕_Ł (OR): bounded sum min(K, a + b) where K is normalization constant
%% - Conjunction/⊗_Ł (AND): bounded sum max(#inf, a + b - K)
%% - Additive identity: #inf (identity for bounded max)
%% - Multiplicative identity: #sup (identity for bounded min with offset)
%% - Interpretation: weights are truth degrees, higher is better
%% - Normalization constant K: parametrizable via CLI (default K=100)
%%
%% PARAMETRIZATION: Normalization Constant K
%% ==========================================
%% The constant K determines the scale of weights in Łukasiewicz logic.
%% Standard Łukasiewicz logic uses [0,1]; we scale to [0,K] for integer arithmetic.
%%
%% Default: K = 100 (scale [0,100])
%% Override via CLI: clingo -c luk_k=1 ... (for [0,1] scale)
%%                   clingo -c luk_k=1000 ... (for [0,1000] scale)
%%
%% Examples:
%%   # Default K=100
%%   clingo core/base.lp semiring/lukasiewicz.lp monoid/max.lp ...
%%
%%   # Use [0,1] scale (standard Łukasiewicz)
%%   clingo -c luk_k=1 core/base.lp semiring/lukasiewicz.lp monoid/max.lp ...
%%
%%   # Use [0,1000] scale (finer granularity)
%%   clingo -c luk_k=1000 core/base.lp semiring/lukasiewicz.lp monoid/max.lp ...

#const luk_k = 100.
%%
%% Łukasiewicz logic is a fuzzy logic where:
%% - Conjunction is "bounded sum": strength decreases more gracefully than min
%% - Disjunction is "bounded sum": strength increases more gracefully than max
%% - More sensitive to weight combinations than Gödel (min/max)
%% - Formulas use K=100 as normalization unit, but identity for unweighted assumptions is #sup

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: SUPREMUM
%% ========================================
%%
%% Unweighted atoms receive the SUPREMUM (maximum value in range):
%% - Matches standard ABA: assumptions accepted by default ("innocent until proven guilty")
%% - "Hardest to discard": attacks from unweighted atoms are maximally expensive
%% - Budget semantics: requires budget ≥ #sup to discard such attacks
%%
%% For Łukasiewicz:
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
%% For Łukasiewicz semiring, unweighted assumptions get #sup (maximum truth degree)
%% Rationale: Unweighted assumptions are "hardest to discard" (default acceptance)
%% - Matches standard ABA semantics: assumptions accepted by default
%% - #sup = positive infinity (supremum, maximum value)
%% - In conjunction (bounded sum): max(#inf, #sup + x - K) = #sup (infinite dominates)
%% - In disjunction (bounded sum): min(K, #sup + x) = K (capped at normalization constant)
%%
%% NOTE: Uses #sup (positive infinity) as supremum.
%% Constraints must handle #sup specially for budget checking.
supported_with_weight(X,#sup) :- assumption(X), in(X), not weight(X,_).

%% Step 1: Compute weight for each rule derivation using conjunction (Łukasiewicz AND)
%% For rule R deriving X: bounded sum of body element weights
%% IMPORTANT: Only compute weight for TRIGGERED rules (all body elements supported)
%%
%% Łukasiewicz AND: max(0, sum(weights) - K*(n-1))
%% where n is the number of body elements, K is the normalization constant
%% This can't be directly expressed in ASP, so we approximate with:
%% - Collect sum of all body weights
%% - Subtract K * (count - 1)
%% - Take max with 0

%% Helper: count body elements for a rule
body_count(R, N) :- head(R,_), N = #count{ B : body(R,B) }.

%% Compute raw sum of body weights
%% Special handling for #sup: clingo's #sum aggregate ignores #sup values
%% If ANY body element has weight #sup, result is #sup (infinite truth propagates)

%% Helper: detect if any body element has #sup weight
body_has_sup_weight(R) :- body(R,B), supported_with_weight(B,#sup).

%% If any body has #sup, sum is #sup (infinite value)
body_sum(R,X,#sup) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    body_has_sup_weight(R).

%% Otherwise, sum finite weights (no #sup values present)
body_sum(R,X,S) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    not body_has_sup_weight(R),
    S = #sum{ V,B : body(R,B), supported_with_weight(B,V) }.

%% Łukasiewicz conjunction: max(0, sum - K*(n-1))
%% If sum is #sup, result is #sup (infinite truth)
rule_derivation_weight(R,X,#sup) :-
    body_sum(R,X,#sup).

%% Otherwise, apply bounded sum formula with parametrized K
rule_derivation_weight(R,X,W) :-
    body_sum(R,X,S),
    S != #sup,
    body_count(R,N),
    W = #max{ 0; S - luk_k*(N-1) }.

%% Handle rules with empty bodies (facts): Use 0 (additive identity)
%% Empty-body rules contribute 0 to the sum (identity for addition)
%% Rationale: Łukasiewicz disjunction uses bounded sum, so 0 is the identity
%% - With explicit weight: min(K, 0 + explicit) = min(K, explicit) ✓
%% - Without explicit weight: min(K, 0) = 0 (but facts typically have explicit weights)
%%
%% NOTE: Uses 0 (additive identity for sum) for algebraic correctness.
%% Assumptions (not facts) get #sup from line 50.
rule_derivation_weight(R,X,0) :-
    head(R,X),
    supported(X),
    not body(R,_).

%% Step 2: Combine multiple derivations using disjunction (Łukasiewicz OR)
%% Łukasiewicz OR: min(K, sum of all derivation weights)
%%
%% For multiple rule derivations and explicit weights, we sum them and cap at K
%%
%% Special handling for #sup: clingo's #sum aggregate ignores #sup values
%% If ANY derivation OR explicit weight is #sup, result is #sup (infinite truth)

%% If any derivation has #sup, result is #sup
supported_with_weight(X,#sup) :-
    supported(X),
    head(_,X),
    rule_derivation_weight(_,X,#sup).

%% If explicit weight is #sup, result is #sup
supported_with_weight(X,#sup) :-
    supported(X),
    head(_,X),
    weight(X,#sup).

%% Otherwise, sum finite values (both derivations and explicit weights) and cap at K
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),
    not rule_derivation_weight(_,X,#sup),
    not weight(X,#sup),
    S = #sum{ V : rule_derivation_weight(_,X,V) ;
              V : weight(X,V) },
    W = #min{ luk_k; S }.
