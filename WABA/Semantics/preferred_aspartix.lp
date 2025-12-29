%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WABA Preferred Semantics (ASPARTIX-based)
%
% Adapted from ASPARTIX preferred_heuristics.lp
% Preferred = Maximal Admissible
%
% Usage: clingo -n 0 --heuristic=Domain --enum=domRec <files>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% S has to be conflict-free
:- in(X), defeated(X).

%% The argument x is not defended by S
not_defended(X) :- assumption(X), contrary(X,Y), not defeated(Y).

%% Admissible: All in arguments must be defended
:- in(X), not_defended(X).

%% Maximality heuristic: prefer including assumptions
%% This guides the search toward maximal admissible extensions
#heuristic in(X) : assumption(X). [1,true]
