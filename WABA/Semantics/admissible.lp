#include "cf.lp".

% Admissibility

derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).
attacked_by_undefeated(X) :- contrary(X,Y), undefeated_weight(Y,W), budget(B), unaffordable_attack(W,B).
:- in(X), attacked_by_undefeated(X).
