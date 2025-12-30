%% Grounded Semantics - Fixpoint Approach
%% Computes grounded extension in g_in/1, then constrains in/1 to match

%% Grounded extension as least fixpoint
g_defeated(X) :- assumption(X), g_in(Y), contrary(X,Y).
g_in(X)       :- assumption(X), g_defeated(Y) : contrary(X,Y).

%% Enforce that the guessed in/1 is exactly the grounded extension
:- g_in(X), not in(X).
:- in(X), not g_in(X).

#show in/1.
