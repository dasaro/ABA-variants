%% Ideal Semantics
%% NOTE: Like ASPforABA, ideal semantics requires Python implementation.
%%
%% The ideal extension is the unique maximal admissible set that is contained
%% in all preferred extensions.
%%
%% ASPforABA approach (aba_solver.py, lines 246-299):
%% 1. Find credulous accepted assumptions (in some admissible extension)
%% 2. Remove conflicting assumptions
%% 3. Iteratively remove non-defended assumptions until fixpoint
%%
%% This cannot be expressed in pure ASP without multi-shot solving or external logic.
%% ASPforABA uses cautious mode (intersection) as a starting point, then Python refinement.
%%
%% For WABA: This currently generates ALL admissible extensions.
%% Proper ideal computation requires external Python processing.
%%
%% Usage: clingo -n 0 <files> semantics/ideal.lp (returns all admissible)
%%        OR implement Python wrapper following ASPforABA's _ideal method

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

%% TODO: Implement full ideal semantics algorithm in Python wrapper or multi-shot ASP
