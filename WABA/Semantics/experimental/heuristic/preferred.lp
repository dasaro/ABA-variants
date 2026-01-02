%% Preferred Semantics (EXPERIMENTAL)
%% Usage: clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/heuristic/preferred.lp

#include "../complete.lp".

%% Track missing assumptions
miss(X) :- assumption(X), not in(X).

%% Heuristic: prefer models with fewer missing assumptions (prefer including assumptions)
%% This should guide the solver toward subset-maximal complete extensions
#heuristic miss(X) : assumption(X). [1,false]
