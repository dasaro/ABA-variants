%% Semi-Stable Semantics (EXPERIMENTAL)
%%
%% Definition: S is semi-stable iff:
%%   1. S is admissible, and
%%   2. range(S) is ⊆-maximal among ranges of admissible sets
%%
%% Where range(S) = S ∪ S⁺ (assumptions in S or attacked by S)
%%
%% Usage: clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/semi-stable.lp
%%
%% Intuition: "Admissible, and attacks as much as possible"
%%
%% WARNING: Uses heuristics to approximate range-maximality. May miss some
%% maximal extensions or include non-maximal ones on complex frameworks.
%% Works correctly on tested examples but not guaranteed in general.

%% Conflict-freeness
:- in(X), defeated(X).

%% Compute closure under undefeated assumptions
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).

%% Attacked by undefeated assumptions (respecting budget-based attack discarding)
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y), supported(Y), not discarded_attack(Y,X,_).
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y), assumption(Y), not supported(Y).

%% Admissibility: in assumptions must not be attacked by undefeated
:- in(X), attacked_by_undefeated(X).

%% Range: assumptions that are in the extension OR defeated by it
%% range(S) = S ∪ S⁺
in_range(X) :- assumption(X), in(X).
in_range(X) :- assumption(X), defeated(X).

%% Track assumptions not in range
not_in_range(X) :- assumption(X), not in_range(X).

%% Heuristic: minimize not_in_range to approximate range-maximality
#heuristic not_in_range(X). [1,false]
