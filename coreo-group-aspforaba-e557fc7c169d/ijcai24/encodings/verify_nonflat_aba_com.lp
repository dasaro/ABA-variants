%% "defeated", "in" and "target" given in input

%% Guess a potential counterexample set
{guess(X)} :- not defeated(X), assumption(X).

%% Everything derivable from in
derived_by_in(X) :- assumption(X), in(X).
derived_by_in(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), derived_by_in(X) : body(R,X).

%% Everything derivable from potential counterexample
derived_by_guess(X) :- assumption(X), guess(X).
derived_by_guess(X) :- head(R,X), triggered_by_guess(R).
triggered_by_guess(R) :- head(R,_), derived_by_guess(X) : body(R,X).

%% Counterexample must be closed
:- assumption(X), derived_by_guess(X), not guess(X).

%% Counterexample must not be defeated by in
:- guess(X), contrary(X,Y), derived_by_in(Y).

defeated_by_guess(X) :- contrary(X,Y), derived_by_guess(Y).

%% Counterexample must defeat the target
:- target(X), not defeated_by_guess(X).

%%% If this encoding is unsat, then the target is not defeated by any closed, undefeated set of assumptions; thus target is defended by in and in is not complete.
