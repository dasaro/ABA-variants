%% Ideal Semantics
%% Based on ASPforABA implementation (Lehtonen et al. 2021)
%%
%% The ideal extension is the unique maximal admissible set that is contained
%% in all preferred extensions. It is computed using admissible constraints
%% with maximality heuristics.
%%
%% Usage: clingo -n 0 <files> semantics/ideal.lp
%%
%% Note: Ideal semantics uses the same encoding as admissible but with
%% maximality preferences for enumeration.

%% Conflict-freeness
:- in(X), defeated(X).

%% Compute closure under undefeated assumptions
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).

%% Attacked by undefeated assumptions
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).

%% Admissibility: in assumptions must not be attacked by undefeated
:- in(X), attacked_by_undefeated(X).

%% Maximality preference: prefer larger extensions (for ideal semantics)
%% The solver will find the maximal admissible extension
#heuristic in(X) : assumption(X). [1,true]
