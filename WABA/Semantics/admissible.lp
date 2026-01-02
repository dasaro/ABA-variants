%% Admissible Semantics
%% Builds upon: Conflict-free

#include "cf.lp".

%% Admissibility: X must be defended against all attackers (actual and potential)
%% Case 1: Y is an assumption - potential attacker even if OUT
not_defended(X) :- contrary(X,Y), assumption(Y), not defeated(Y), not discarded_attack(Y,X,_).
%%
%% Case 2: Y is supported - actual attacker (covers derived elements and IN assumptions)
not_defended(X) :- contrary(X,Y), supported(Y), not defeated(Y), not discarded_attack(Y,X,_).

:- in(X), not_defended(X).