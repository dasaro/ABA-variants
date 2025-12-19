%% Tropical Semiring for Weight Propagation
%% Semiring: (ℝ ∪ {∞}, min, +, ∞, 0)
%% - Disjunction/⊕ (OR, multiple derivations): min (choose best path)
%% - Conjunction/⊗ (AND, body elements): + (accumulate costs)
%% - Additive identity: ∞
%% - Multiplicative identity: 0
%% - Interpretation: weights are costs, lower is better
%%
%% This is the TRUE tropical semiring used for shortest path problems.

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: SUPREMUM
%% ========================================
%%
%% Unweighted atoms receive the SUPREMUM (maximum value in range):
%% - Matches standard ABA: assumptions accepted by default ("innocent until proven guilty")
%% - "Hardest to discard": attacks from unweighted atoms are maximally expensive
%% - Budget semantics: attacks with cost #sup (∞) CANNOT be discarded
%%
%% For Tropical:
%% - Supremum = #sup (∞, infinite cost)
%% - Meaning: Unweighted assumptions have infinite cost (unbounded)
%% - Discard cost with max monoid: max(#sup, ...) = #sup (impossible to discard!)
%% - Discard cost with min monoid: min(#sup, ...) = other values (doesn't contribute)
%% - Discard cost with sum monoid: sum + #sup = #sup (impossible to discard!)
%%
%% Note: This makes unweighted attacks IMPOSSIBLE to discard (not just expensive).
%% Only attacks with explicit finite costs can be discarded within budget constraints.
%%
%% Explicit weights REPLACE the supremum default (via mutually exclusive rules).
%% DEFAULT WEIGHTS for unweighted atoms are now defined in monoid/*.lp files,
%% since the monoid determines what "hard to discard" means.
%%

%% Assumptions with explicit weights
supported_with_weight(X,W) :- assumption(X), in(X), weight(X,W).

%% Step 1: Compute weight for each rule derivation using conjunction (addition)
%% For rule R deriving X: sum the weights of all body elements
%% IMPORTANT: Only compute weight for TRIGGERED rules (all body elements supported)
rule_derivation_weight(R,X,W) :-
    head(R,X),
    supported(X),
    body(R,_),  % Only for rules with bodies
    triggered_by_in(R),  % Only triggered rules (prevents incorrect weights from unsupported bodies)
    W = #sum{ V,B : body(R,B), supported_with_weight(B,V) }.

%% Handle rules with empty bodies (facts): multiplicative identity (NOT supremum)
%% IMPORTANT: Facts use 0 (multiplicative identity for empty sum), not #sup (supremum).
%% This is correct because: sum({}) = 0 (additive identity for empty conjunction).
%% Supremum (#sup) applies only to unweighted assumptions, not to derivation rules.
rule_derivation_weight(R,X,0) :-
    head(R,X),
    supported(X),
    not body(R,_).

%% Step 2: Combine multiple derivations using disjunction (minimum)
%% The weight of X is the minimum across all its rule derivations
%% AND any explicit weight (OR semantics: explicit weight is another "derivation")
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),  % X is derived (not just an assumption)
    W = #min{ V : rule_derivation_weight(_,X,V) ;
              V : weight(X,V) }.
