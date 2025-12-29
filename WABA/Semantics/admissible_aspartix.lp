%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WABA Admissible Semantics (ASPARTIX-based)
%
% Translated from ASPARTIX adm.lp
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% S has to be conflict-free
%% WABA: Use defeated/1 from core (cleaner than explicit check)
:- in(X), defeated(X).

%% The argument x is not defended by S
%% ASPARTIX: not_defended(X) :- att(Y,X), not defeated(Y).
%% WABA: contrary(X,Y) means Y attacks X (parameters reversed!)
not_defended(X) :- assumption(X), contrary(X,Y), not defeated(Y).

%% All arguments x \in S need to be defended by S
:- in(X), not_defended(X).
