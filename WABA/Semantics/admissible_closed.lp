%% Admissible Semantics with Closure Constraint (Non-Flat ABA)
%% Based on ASPforABA IJCAI'24 implementation
%%
%% Extension must be:
%% 1. Conflict-free
%% 2. Self-defending (admissible)
%% 3. Closed: all assumptions derived from the extension must be in the extension
%%
%% Usage: clingo -n 0 <files> semantics/admissible_closed.lp

%% Conflict-freeness
:- in(X), defeated(X).

%% Compute what is derived from the extension
derived(X) :- assumption(X), in(X).
derived(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), derived(X) : body(R,X).

%% Closure constraint: all derived assumptions must be in
:- assumption(X), derived(X), not in(X).

%% Compute closure under undefeated assumptions
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).

%% Attacked by undefeated assumptions
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).

%% Admissibility: in assumptions must not be attacked by undefeated
:- in(X), attacked_by_undefeated(X).
