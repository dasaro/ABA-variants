%% Naive Semantics: Maximal Conflict-Free Extensions
%%
%% Usage: clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/naive.lp
%%
%% Uses heuristic to minimize missing assumptions, achieving subset-maximality
%% for conflict-free extensions.

%% Conflict-freeness
:- in(X), defeated(X).

%% Track missing assumptions
miss(X) :- assumption(X), not in(X).

%% Maximality heuristic: prefer models with fewer missing assumptions
#heuristic miss(X) : assumption(X). [1,false]
