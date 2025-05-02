%% Assumption is either in or out
in(X) :- assumption(X), not out(X).
out(X) :- assumption(X), not in(X).

%% Everything derivable from assumptions that are in
supported(X) :- assumption(X), in(X).
supported(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).

%% conflict freeness
:- in(X), contrary(X,Y), supported(Y).

% naive
% Use: clingo -n 0 --heuristic=Domain --enum=domRec --out-hide aba_instance.lp Semantics/naive.lp
#heuristic in(X) : assumption(X). [1,true]

#show in/1.
#show supported/1.
