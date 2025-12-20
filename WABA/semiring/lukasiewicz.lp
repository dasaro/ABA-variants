%% Łukasiewicz Semiring for Weight Propagation
%% Semiring: (ℤ ∪ {±∞}, ⊕_Ł, ⊗_Ł, #inf, #sup)
%% - Domain: All integers plus infinities (typically bounded in [0,100])
%% - Disjunction/⊕_Ł (OR): bounded sum min(#sup, a + b)
%% - Conjunction/⊗_Ł (AND): bounded sum max(#inf, a + b - 100)
%% - Additive identity: #inf (identity for bounded max)
%% - Multiplicative identity: #sup (identity for bounded min with offset)
%% - Interpretation: weights are truth degrees, higher is better
%%
%% Łukasiewicz logic is a fuzzy logic where:
%% - Conjunction is "bounded sum": strength decreases more gracefully than min
%% - Disjunction is "bounded sum": strength increases more gracefully than max
%% - More sensitive to weight combinations than Gödel (min/max)
%% - Domain typically restricted to [0,100] for practical use

%% ========================================
%% DEFAULT WEIGHT PRINCIPLE: SUPREMUM
%% ========================================
%%
%% Unweighted atoms receive the SUPREMUM (maximum value in range):
%% - Matches standard ABA: assumptions accepted by default ("innocent until proven guilty")
%% - "Hardest to discard": attacks from unweighted atoms are maximally expensive
%% - Budget semantics: requires budget ≥ 100 to discard such attacks
%%
%% For Łukasiewicz:
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

%% Step 1: Compute weight for each rule derivation using conjunction (Łukasiewicz AND)
%% For rule R deriving X: bounded sum of body element weights
%% IMPORTANT: Only compute weight for TRIGGERED rules (all body elements supported)
%%
%% Łukasiewicz AND: max(0, sum(weights) - 100*(n-1))
%% where n is the number of body elements
%% This can't be directly expressed in ASP, so we approximate with:
%% - Collect sum of all body weights
%% - Subtract 100 * (count - 1)
%% - Take max with 0

%% Helper: count body elements for a rule
body_count(R, N) :- head(R,_), N = #count{ B : body(R,B) }.

%% Compute raw sum of body weights
body_sum(R,X,S) :-
    head(R,X),
    supported(X),
    body(R,_),
    triggered_by_in(R),
    S = #sum{ V,B : body(R,B), supported_with_weight(B,V) }.

%% Łukasiewicz conjunction: max(0, sum - 100*(n-1))
rule_derivation_weight(R,X,W) :-
    body_sum(R,X,S),
    body_count(R,N),
    W = #max{ 0; S - 100*(N-1) }.

%% Handle rules with empty bodies (facts): conjunction identity (#sup)
%% Empty conjunction = identity element for the AND operation
%% Note: Using #sup (true identity) for empty bounded sum
rule_derivation_weight(R,X,#sup) :-
    head(R,X),
    supported(X),
    not body(R,_).

%% Step 2: Combine multiple derivations using disjunction (Łukasiewicz OR)
%% Łukasiewicz OR: min(100, sum of all derivation weights)
%%
%% For multiple rule derivations and explicit weights, we sum them and cap at 100

%% Collect all weight sources (derivations + explicit)
weight_source(X,V) :- rule_derivation_weight(_,X,V).
weight_source(X,V) :- supported(X), head(_,X), weight(X,V).

%% Sum all sources and cap at 100
supported_with_weight(X,W) :-
    supported(X),
    head(_,X),
    weight_source(X,_),
    S = #sum{ V : weight_source(X,V) },
    W = #min{ 100; S }.
