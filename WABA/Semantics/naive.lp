%% conflict freeness
:- in(X), contrary(X,Y), supported(Y).

% naive
% Use: clingo -n 0 --heuristic=Domain --enum=domRec --out-hide aba_instance.lp Semantics/naive.lp
#heuristic in(X) : assumption(X). [1,true]
