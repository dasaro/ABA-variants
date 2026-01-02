%% Semi-Stable Semantics (EXPERIMENTAL)
%% Usage: clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/heuristic/semi-stable.lp

#include "../admissible.lp".

%% Range: assumptions that are in the extension OR defeated by it
in_range(X) :- assumption(X), in(X).
in_range(X) :- assumption(X), defeated(X).

%% Track assumptions not in range
not_in_range(X) :- assumption(X), not in_range(X).

%% Heuristic: minimize not_in_range to approximate range-maximality
#heuristic not_in_range(X). [1,false]
