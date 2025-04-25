%% conflict freeness
:- in(X), attacks(Y,X,_), not discarded_attack(Y,X), supported(Y).

%% stable
defeated(X) :- supported(Y), attacks(Y,X,_), not discarded_attack(Y,X).
:- not defeated(X), out(X).
