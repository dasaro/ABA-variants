%% Guess an extension
1{ in(X); out(X) }1 :- assumption(X).

%% Conflict-free on successful attacks
:- supported(X), in(Y), attacks_successfully_with_weight(X,Y,_).

%% Defeated-by-S (counterattacked)
defeated(Y) :- supported(Z), assumption(Y), attacks_successfully_with_weight(Z,Y,_).

%% stable
:- not defeated(X), out(X).
