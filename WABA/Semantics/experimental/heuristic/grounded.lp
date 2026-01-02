%% Grounded Semantics (EXPERIMENTAL)
%% Usage: clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/heuristic/grounded.lp

#include "../complete.lp".

#heuristic in(X) : assumption(X). [1,false]