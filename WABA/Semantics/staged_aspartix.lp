%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WABA Staged Semantics (ASPARTIX-based)
%
% Translated from ASPARTIX stage_gringo.lp
% Staged = Conflict-free with maximal range
% Range = S ∪ defeated(S)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% S has to be conflict-free
:- in(X), defeated(X).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Ordering for iterative computation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lt(X,Y) :- assumption(X), assumption(Y), X<Y.
nsucc(X,Z) :- lt(X,Y), lt(Y,Z).
succ(X,Y) :- lt(X,Y), not nsucc(X,Y).
ninf(X) :- lt(Y,X).
nsup(X) :- lt(X,Y).
inf(X) :- not ninf(X), assumption(X).
sup(X) :- not nsup(X), assumption(X).

%% Computing the range S+ of the guessed set S
%% Range = S ∪ {X | X is defeated by S}
in_range(X) :- in(X).
in_range(X) :- defeated(X).
not_in_range(X) :- assumption(X), not in_range(X).

%% Guess S' for range comparison
inN(X) | outN(X) :- assumption(X).

%% Compute range of S'
%% ASPARTIX: in_rangeN(X) :- inN(X).
%% ASPARTIX: in_rangeN(X) :- outN(X), inN(Y), att(Y,X).
%% WABA: contrary(X,Y) means Y attacks X
in_rangeN(X) :- inN(X).
in_rangeN(X) :- outN(X), inN(Y), contrary(X,Y).
not_in_rangeN(X) :- assumption(X), not in_rangeN(X).

%% eqplus checks whether range(S') equals range(S)
eqplus_upto(X) :- inf(X), in_range(X), in_rangeN(X).
eqplus_upto(X) :- inf(X), not_in_range(X), not_in_rangeN(X).
eqplus_upto(X) :- succ(Z,X), in_range(X), in_rangeN(X), eqplus_upto(Z).
eqplus_upto(X) :- succ(Z,X), not_in_range(X), not_in_rangeN(X), eqplus_upto(Z).

eqplus :- sup(X), eqplus_upto(X).

%% Saturation: fail if S is not maximal

%% S' has to be conflict-free
fail :- inN(X), inN(Y), contrary(Y,X).

%% Fail if range(S') = range(S) (no improvement)
fail :- eqplus.

%% Fail if range(S') ⊂ range(S) (S' has smaller range)
fail :- in_range(X), not_in_rangeN(X).

%% Saturation: if failed, make all inN/outN true (contradiction)
inN(X) :- fail, assumption(X).
outN(X) :- fail, assumption(X).

%% Reject if not failed (i.e., accept only if fail is false)
:- not fail.
