%% Fuzzy Semiring for Weight Propagation (Gödel Logic)
%% Semiring: ([0,100], max, min, 0, 100)
%% - Disjunction/⊕ (OR, multiple derivations): max (strongest alternative)
%% - Conjunction/⊗ (AND, body elements): min (weakest link)
%% - Additive identity: 0
%% - Multiplicative identity: 100
%% - Interpretation: weights are truth degrees, higher is better
%%
%% In fuzzy logic:
%% - Weights represent truth degrees in [0,100]
%% - Conjunction takes the minimum (weakest link in a chain)
%% - Disjunction takes the maximum (strongest of multiple proofs)

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: SUPREMUM
%% ========================================
%%
%% Unweighted atoms receive the SUPREMUM (maximum value in range):
%% - Matches standard ABA: assumptions accepted by default ("innocent until proven guilty")
%% - "Hardest to discard": attacks from unweighted atoms are maximally expensive
%% - Budget semantics: requires budget ≥ 100 to discard such attacks
%%
%% For Fuzzy (Gödel):
%% - Supremum = 100 (fully true, maximum truth degree)
%% - Meaning: Unweighted assumptions have maximum truth value
%% - Discard cost with max monoid: max(100, ...) ≥ 100 (very expensive)
%% - Discard cost with min monoid: min(100, ...) ≤ 100 (contributes to baseline)
%% - Discard cost with sum monoid: sum += 100 per attack (significant contribution)
%%
%% Explicit weights REPLACE the supremum default (via mutually exclusive rules).
%% DEFAULT WEIGHTS for unweighted atoms are now defined in monoid/*.lp files,
%% since the monoid determines what "hard to discard" means.
%%

%% Assumptions with explicit weights
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W).

%% Step 1: Compute weight for each rule derivation using conjunction (minimum)
%% For rule R deriving X: take minimum weight among all body elements
%% IMPORTANT: Only compute weight for TRIGGERED rules (all body elements supported)
rule_derivation_weight(R,X,W) :-
    head(R,X),
    supported(X),
    body(R,_),  % Only for rules with bodies
    triggered_by_in(R),  % Only triggered rules (prevents #sup from unsupported bodies)
    W = #min{ V,B : body(R,B), supported_with_weight(B,V) }.

%% Handle rules with empty bodies (facts): conjunction identity (100 for min)
%% Empty conjunction = identity element for the AND operation (min)
rule_derivation_weight(R,X,100) :-
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
