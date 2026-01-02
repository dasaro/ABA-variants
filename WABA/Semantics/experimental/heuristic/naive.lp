%% Naive Semantics (EXPERIMENTAL)
%% Usage: clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/heuristic/naive.lp

%% Conflict-freeness
:- in(X), defeated(X).

%% Track missing assumptions
miss(X) :- assumption(X), not in(X).

%% Maximality heuristic: prefer models with fewer missing assumptions
#heuristic miss(X) : assumption(X). [1,false]
