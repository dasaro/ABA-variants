%% Staged Semantics
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

%% Conflict-freeness
:- in(X), defeated(X).

%% Range: assumptions that are in the extension OR defeated by it
%% range(S) = S ∪ S⁺
in_range(X) :- assumption(X), in(X).
in_range(X) :- assumption(X), defeated(X).

%% Track assumptions not in range
not_in_range(X) :- assumption(X), not in_range(X).

%% Triple heuristics: maximize range from multiple angles
#heuristic in_range(X). [3,true]           % Maximize in_range atoms (highest priority)
#heuristic in(X) : assumption(X). [2,true] % Maximize in assumptions
#heuristic not_in_range(X). [2,false]      % Minimize not_in_range atoms
