%% Assumption is either in or out
in(X) :- assumption(X), not out(X).
out(X) :- assumption(X), not in(X).

%% Everything derivable from assumptions that are in
supported(X) :- assumption(X), in(X).
supported(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).

%% conflict freeness
:- in(X), contrary(X,Y), supported(Y).

%% assumptions attacked by the in arguments
defeated(X) :- supported(Y), contrary(X,Y).

%% stable
:- not defeated(X), out(X).

#show in/1.
#show supported/1.
