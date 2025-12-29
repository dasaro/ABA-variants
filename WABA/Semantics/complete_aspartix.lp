%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WABA Complete Semantics (ASPARTIX-based)
%
% Translated from ASPARTIX comp.lp
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
%% ASPARTIX: :- out(X), not not_defended(X).
%% Equivalent: :- out(X), defended(X).
%%   where defended(X) means "not not_defended(X)"
:- out(X), assumption(X), not not_defended(X).
