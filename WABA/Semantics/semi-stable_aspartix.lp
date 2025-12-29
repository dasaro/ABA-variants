%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WABA Semi-stable Semantics (ASPARTIX-based)
%
% Translated from ASPARTIX semi_stable_gringo.lp
% Semi-stable = Admissible with maximal range (S ∪ defeated)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% S has to be conflict-free
:- in(X), defeated(X).

%% The argument x is not defended by S
%% WABA: contrary(X,Y) means Y attacks X
not_defended(X) :- assumption(X), contrary(X,Y), not defeated(Y).

%% Admissible: All in arguments must be defended
:- in(X), not_defended(X).

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

%% Guess S' ⊇ S for range maximality check
inN(X) | outN(X) :- assumption(X).

%% S' must be a superset of S
:- in(X), outN(X).

%% eqplus checks whether range(S') equals range(S)
%% Range(S) = S ∪ {X | X is defeated by S}

%% Base case and iterative construction
eqplus_upto(Y) :- inf(Y), in(Y), inN(Y).
eqplus_upto(Y) :- inf(Y), in(Y), inN(X), contrary(Y,X).
eqplus_upto(Y) :- inf(Y), in(X), inN(Y), contrary(Y,X).
eqplus_upto(Y) :- inf(Y), in(X), inN(Z), contrary(Y,X), contrary(Y,Z).
eqplus_upto(Y) :- inf(Y), out(Y), outN(Y), not defeated(Y), undefeated(Y).

eqplus_upto(Y) :- succ(Z,Y), in(Y), inN(Y), eqplus_upto(Z).
eqplus_upto(Y) :- succ(Z,Y), in(Y), inN(X), contrary(Y,X), eqplus_upto(Z).
eqplus_upto(Y) :- succ(Z,Y), in(X), inN(Y), contrary(Y,X), eqplus_upto(Z).
eqplus_upto(Y) :- succ(Z,Y), in(X), inN(U), contrary(Y,X), contrary(Y,U), eqplus_upto(Z).
eqplus_upto(Y) :- succ(Z,Y), out(Y), outN(Y), not defeated(Y), undefeated(Y), eqplus_upto(Z).

eqplus :- sup(Y), eqplus_upto(Y).

%% Compute undefeated arguments in S'
undefeated_upto(X,Y) :- inf(Y), outN(X), outN(Y).
undefeated_upto(X,Y) :- inf(Y), outN(X), not contrary(X,Y).

undefeated_upto(X,Y) :- succ(Z,Y), undefeated_upto(X,Z), outN(Y).
undefeated_upto(X,Y) :- succ(Z,Y), undefeated_upto(X,Z), not contrary(X,Y).

undefeated(X) :- sup(Y), undefeated_upto(X,Y).

%% Saturation: spoil if not semi-stable

%% Spoil if range(S') = range(S) (no improvement possible)
spoil :- eqplus.

%% S' has to be conflict-free
spoil :- inN(X), inN(Y), contrary(Y,X).

%% Spoil if S' is not admissible
spoil :- inN(X), outN(Y), contrary(X,Y), undefeated(Y).

%% Spoil if there's an argument in S but not in S' that's undefeated in S'
spoil :- in(X), outN(X), undefeated(X).

%% Spoil if S defeats X but S' doesn't
spoil :- in(Y), contrary(X,Y), outN(X), undefeated(X).

%% Saturation: if spoiled, make all inN/outN true (contradiction)
inN(X) :- spoil, assumption(X).
outN(X) :- spoil, assumption(X).

%% Reject if not spoiled (i.e., accept only if spoil is false)
:- not spoil.
