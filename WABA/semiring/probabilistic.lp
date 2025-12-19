%% Probabilistic Semiring for Weight Propagation (Viterbi Semiring)
%% Semiring: ([0,100], max, ×, 0, 100)
%% - Disjunction/⊕ (OR, multiple derivations): max (most likely path)
%% - Conjunction/⊗ (AND, body elements): × (product of probabilities)
%% - Additive identity: 0
%% - Multiplicative identity: 100
%% - Interpretation: weights are probability percentages [0,100]
%%
%% This is the Viterbi semiring used in probabilistic parsing.
%% For independent events: P(A AND B) = P(A) × P(B) / 100
%% For alternatives: P(A OR B) ≈ max(P(A), P(B)) (most likely)
%%
%% Note: True probability sum would give P(A OR B) = P(A) + P(B) - P(A)×P(B)/100
%% but max is computationally simpler and standard in Viterbi semiring.

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: SUPREMUM
%% ========================================
%%
%% Unweighted atoms receive the SUPREMUM (maximum value in range):
%% - Matches standard ABA: assumptions accepted by default ("innocent until proven guilty")
%% - "Hardest to discard": attacks from unweighted atoms are maximally expensive
%% - Budget semantics: requires budget ≥ 100 to discard such attacks
%%
%% For Probabilistic (Viterbi):
%% - Supremum = 100 (certain, 100% probability)
%% - Meaning: Unweighted assumptions have maximum probability
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

%% Step 1: Compute weight for each rule derivation using conjunction (product)
%% For rule R deriving X: multiply probabilities of all body elements
%%
%% LIMITATION: ASP doesn't support product aggregates (#prod doesn't exist in clingo)
%% We use MINIMUM as an approximation (pessimistic, similar to fuzzy logic)
%% For true probabilistic semantics, encode weights as negative log-probabilities
%% and use tropical semiring where sum = product in probability space.
%%
%% Approximation: min(P(A), P(B)) ≤ P(A) × P(B) / 100 ≤ min(P(A), P(B))
%% This gives a conservative (lower bound) estimate of the conjunction.

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
%% The weight of X is the maximum probability across all derivations (Viterbi)
%% AND any explicit weight (OR semantics: explicit weight is another "derivation")
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),  % X is derived (not just an assumption)
    W = #max{ V : rule_derivation_weight(_,X,V) ;
              V : weight(X,V) }.
