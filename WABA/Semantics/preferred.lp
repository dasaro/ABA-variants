%% Preferred Semantics
%% Maximal complete extensions (w.r.t. set inclusion)
%%
%% Uses domain heuristics to guide solver toward subset-maximal extensions
%% USAGE: clingo -n 0 --heuristic=Domain --enum-mode=domRec [files]

#include "complete.lp".

%% Track missing assumptions (OUT assumptions)
miss(X) :- out(X), assumption(X).

%% Heuristic: Prefer models with fewer missing assumptions
%% This guides the solver to find maximal (subset-wise) extensions
#heuristic miss(X) : assumption(X). [1,false]
