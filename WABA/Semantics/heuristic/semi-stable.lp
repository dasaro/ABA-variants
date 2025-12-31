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

%% Admissibility: X must be defended against all attackers (actual and potential)
%% Case 1: Y is an assumption - potential attacker even if OUT
not_defended(X) :- contrary(X,Y), assumption(Y), not defeated(Y), not discarded_attack(Y,X,_).
%% Case 2: Y is supported - actual attacker (covers derived elements and IN assumptions)
not_defended(X) :- contrary(X,Y), supported(Y), not defeated(Y), not discarded_attack(Y,X,_).

%% Admissibility: in assumptions must not be attacked by undefeated
:- in(X), not_defended(X).

%% Range: assumptions that are in the extension OR defeated by it
%% range(S) = S ∪ S⁺
in_range(X) :- assumption(X), in(X).
in_range(X) :- assumption(X), defeated(X).

%% Track assumptions not in range
not_in_range(X) :- assumption(X), not in_range(X).

%% Heuristic: minimize not_in_range to approximate range-maximality
#heuristic not_in_range(X). [1,false]
