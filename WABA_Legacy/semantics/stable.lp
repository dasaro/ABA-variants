%% conflict freeness
:- in(X), defeated(X).

%% stable
:- not defeated(X), out(X).
