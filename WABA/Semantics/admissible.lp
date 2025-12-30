%% Admissible Semantics
%% Based on ASPforABA implementation (Lehtonen et al. 2021)
%%
%% An extension is admissible if it is conflict-free and defends all its members.
%%
%% Usage: clingo -n 0 <files> semantics/admissible.lp
%%
%% Conflict-free: No assumption in the extension is defeated
%% Self-defending: Every assumption must not be attacked by undefeated assumptions

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
