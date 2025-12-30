%% Assumption is either in or out
in(X) :- assumption(X), not out(X).
out(X) :- assumption(X), not in(X).

%% Everything derivable from assumptions that are in
derived(X) :- assumption(X), in(X).
derived(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), derived(X) : body(R,X).

%% Conflict freeness
:- in(X), contrary(X,Y), derived(Y).

%% In is closed
:- assumption(X), derived(X), not in(X).

%% assumptions attacked by the in arguments
defeated(X) :- derived(Y), contrary(X,Y).

%% In attacks every assumption that is out
:- out(X), not defeated(X).

#show in/1.
#show defeated/1.
#show derived/1.
