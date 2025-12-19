%% Boolean Semiring for Weight Propagation
%% Semiring: ({0, 1}, max, min, 0, 1)
%% - Disjunction/⊕ (OR, multiple derivations): max (numeric OR on {0,1})
%% - Conjunction/⊗ (AND, body elements): min (numeric AND on {0,1})
%% - Additive identity: 0 (false)
%% - Multiplicative identity: 1 (true)
%% - Weights are binary: 0 (false) or 1 (true)
%%
%% This represents boolean algebra using numeric {0,1} weights:
%% - AND = min: min(0,1)=0, min(1,1)=1
%% - OR  = max: max(0,1)=1, max(0,0)=0

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: SUPREMUM
%% ========================================
%%
%% Unweighted atoms receive the SUPREMUM (maximum value in range):
%% - Matches standard ABA: assumptions accepted by default ("innocent until proven guilty")
%% - "Hardest to discard": attacks from unweighted atoms are maximally expensive
%% - Budget semantics: requires budget ≥ 1 to discard such attacks
%%
%% For Boolean:
%% - Supremum = 1 (true)
%% - Meaning: Unweighted assumptions are true by default
%% - Discard cost with max monoid: max(1, ...) ≥ 1 (requires budget ≥ 1)
%% - Discard cost with min monoid: min(1, ...) ≤ 1 (contributes to baseline)
%% - Discard cost with sum monoid: sum += 1 per attack (counts attacks)
%%
%% Explicit weights REPLACE the supremum default (via mutually exclusive rules).
%% DEFAULT WEIGHTS for unweighted atoms are now defined in monoid/*.lp files,
%% since the monoid determines what "hard to discard" means.
%%

%% Assumptions with explicit weights (should be 0 or 1)
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W).

%% Step 1: Compute weight for each rule derivation using conjunction (min)
%% For rule R deriving X: take minimum weight among all body elements
%% IMPORTANT: Only compute weight for TRIGGERED rules (all body elements supported)
rule_derivation_weight(R,X,W) :-
    head(R,X),
    supported(X),
    body(R,_),  % Only for rules with bodies
    triggered_by_in(R),  % Only triggered rules (prevents #sup from unsupported bodies)
    W = #min{ V,B : body(R,B), supported_with_weight(B,V) }.

%% Empty body rules (facts) succeed with conjunction identity (1 for AND)
%% Empty conjunction = identity element for the AND operation
rule_derivation_weight(R,X,1) :-
    head(R,X),
    supported(X),
    not body(R,_).

%% Step 2: Combine multiple derivations using disjunction (max)
%% The weight of X is the maximum across all its rule derivations
%% AND any explicit weight (OR semantics: explicit weight is another "derivation")
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),  % X is derived (not just an assumption)
    W = #max{ V : rule_derivation_weight(_,X,V) ;
              V : weight(X,V) }.
