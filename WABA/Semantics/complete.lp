%% Complete Semantics
%% Based on ASPforABA implementation (Lehtonen et al. 2021)
%%
%% An extension is complete if it is admissible and contains all assumptions it defends.
%%
%% Admissible: Conflict-free + self-defending
%% Complete: Admissible + for every assumption X that is defended, X must be in

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

%% Completeness: All unattacked (defended) assumptions must be in
:- out(X), not attacked_by_undefeated(X).
