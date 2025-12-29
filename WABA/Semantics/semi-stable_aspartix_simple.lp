%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WABA Semi-stable Semantics (ASPARTIX-based, Simplified)
%
% Semi-stable = Complete with maximal range
% Range = S ∪ defeated(S)
%
% This version uses heuristics instead of saturation
% Usage: clingo -n 0 --heuristic=Domain --enum=domRec <files>
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% S has to be conflict-free
:- in(X), defeated(X).

%% The argument x is not defended by S
%% ASPARTIX: not_defended(X) :- att(Y,X), not defeated(Y).
%% WABA: contrary(X,Y) means Y attacks X
not_defended(X) :- assumption(X), contrary(X,Y), not defeated(Y).

%% Admissible: All in arguments must be defended
:- in(X), not_defended(X).

%% Complete: Every defended argument must be in
:- out(X), assumption(X), not not_defended(X).

%% Heuristic to maximize range (S ∪ defeated)
%% Prefer including defended assumptions to attack more arguments
#heuristic in(X) : assumption(X), not not_defended(X). [1,true]
