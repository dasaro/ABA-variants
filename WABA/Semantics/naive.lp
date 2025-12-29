%% Naive Semantics: Maximal Conflict-Free Extensions
%%
%% Usage: clingo -n 0 --heuristic=Domain --enum=domRec <files> semantics/naive.lp
%%
%% The heuristic prefers including assumptions, and domRec enumeration
%% explores different ways to maximize the extension.

%% Conflict-freeness
:- in(X), defeated(X).

%% Maximality heuristic: prefer including assumptions
#heuristic in(X) : assumption(X). [1,true]
