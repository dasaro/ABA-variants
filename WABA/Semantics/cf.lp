defeated(X) :- attacks_successfully_with_weight(_,X,_).
1{ in(X); out(X) }1 :- assumption(X).
:- in(X), defeated(X).