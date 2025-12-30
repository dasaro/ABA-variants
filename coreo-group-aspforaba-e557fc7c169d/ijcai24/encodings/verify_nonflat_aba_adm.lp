%% both "defeated" and "in" given in input
#defined defeated/1.
#defined in/1.

%% Guess a potential counterexample
{guess(X)} :- not defeated(X), assumption(X).

%% Everything derived from in
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

%% Counterexample must defeat in
%:- in(X), not defeated_by_guess(X).
in_defeated_by_guess :- in(X), contrary(X,Y), derived_by_guess(Y).
:- not in_defeated_by_guess.

extra_derived(X) :- assumption(X), derived_by_guess(X), not guess(X).

%#show guess/1.
%#show derived_by_guess/1.
%#show extra_derived/1.
