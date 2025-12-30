%% Staged Semantics (EXPERIMENTAL)
%%
%% Definition: S is staged iff:
%%   1. S is conflict-free, and
%%   2. range(S) is ⊆-maximal among ranges of conflict-free sets
%%
%% Where range(S) = S ∪ S⁺ (assumptions in S or attacked by S)
%%
%% Usage: clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/staged.lp
%%
%% Intuition: "Like semi-stable but dropping admissibility—purely range-maximizing conflict-free sets"
%%
%% WARNING: Uses heuristics to approximate range-maximality. May miss some
%% maximal extensions or include non-maximal ones on complex frameworks.
%% Works correctly on tested examples but not guaranteed in general.

%% Conflict-freeness
:- in(X), defeated(X).

%% Range: assumptions that are in the extension OR defeated by it
%% range(S) = S ∪ S⁺
in_range(X) :- assumption(X), in(X).
in_range(X) :- assumption(X), defeated(X).

%% Track assumptions not in range
not_in_range(X) :- assumption(X), not in_range(X).

%% Heuristic: minimize not_in_range to approximate range-maximality
#heuristic not_in_range(X). [1,false]
