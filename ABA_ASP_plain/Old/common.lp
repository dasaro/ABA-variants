in(X) :- not out(X), assumption(X).
out(X) :- not in(X), assumption(X).
supported(X) :- assumption(X), in(X).
supported(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).
:- in(X), contrary(X,Y), supported(Y).
defeated(X) :- supported(Y), contrary(X,Y).
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).
:- in(X), attacked_by_undefeated(X).
%:- out(X), not attacked_by_undefeated(X).
#show in/1. #show supported/1.