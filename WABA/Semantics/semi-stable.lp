%% Semi-Stable Semantics
%%
%% Definition: S is semi-stable iff:
%%   1. S is admissible, and
%%   2. range(S) is ⊆-maximal among ranges of admissible sets
%%
%% Where range(S) = S ∪ S⁺ (assumptions in S or attacked by S)
%%
%% Usage: clingo -n 0 --opt-mode=optN <files> semantics/semi-stable.lp
%%        (use optN to enumerate all range-maximal extensions)
%%
%% Intuition: "Admissible, and attacks as much as possible"

%% Conflict-freeness
:- in(X), defeated(X).

%% Compute closure under undefeated assumptions
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).

%% Attacked by undefeated assumptions
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).

%% Admissibility: in assumptions must not be attacked by undefeated
:- in(X), attacked_by_undefeated(X).

%% Range: assumptions that are in the extension OR defeated by it
%% range(S) = S ∪ S⁺
in_range(X) :- assumption(X), in(X).
in_range(X) :- assumption(X), defeated(X).

%% Maximize range (minimize assumptions not in range)
%% Use weak constraint to prefer extensions with larger ranges
:~ not in_range(X), assumption(X). [1,X]
