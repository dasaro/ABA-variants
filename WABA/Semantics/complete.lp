%% Complete Semantics
%% Based on ASPforABA implementation (Lehtonen et al. 2021)
%%
%% An extension is complete if it is admissible and contains all assumptions it defends.
%%
%% Admissible: Conflict-free + self-defending
%% Complete: Admissible + for every assumption X that is defended, X must be in

%% Conflict-freeness
:- in(X), defeated(X).

%% Admissibility: X must be defended against all attackers (actual and potential)
%% Case 1: Y is an assumption - potential attacker even if OUT
not_defended(X) :- contrary(X,Y), assumption(Y), not defeated(Y), not discarded_attack(Y,X,_).
%% Case 2: Y is supported - actual attacker (covers derived elements and IN assumptions)
not_defended(X) :- contrary(X,Y), supported(Y), not defeated(Y), not discarded_attack(Y,X,_).

%% Admissibility: in assumptions must not be attacked by undefeated
:- in(X), not_defended(X).

%% Completeness: All defended assumptions must be in
:- out(X), assumption(X), not not_defended(X).
