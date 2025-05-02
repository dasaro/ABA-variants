%% conflict freeness
:- in(X), defeated(X).

% naive
% Use: clingo -n 0 --heuristic=Domain --enum=domRec aba_instance.lp Semantics/naive.lp
#heuristic in(X) : assumption(X). [1,true]
