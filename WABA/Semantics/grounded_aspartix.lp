%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% WABA Grounded Semantics (ASPARTIX-based)
%
% Translated from ASPARTIX ground.lp
% Grounded = Least Fixed Point of Defended Arguments
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Put an order on the domain for iterative construction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

lt(X,Y) :- assumption(X), assumption(Y), X<Y.
nsucc(X,Z) :- lt(X,Y), lt(Y,Z).
succ(X,Y) :- lt(X,Y), not nsucc(X,Y).
ninf(X) :- lt(Y,X).
nsup(X) :- lt(X,Y).
inf(X) :- not ninf(X), assumption(X).
sup(X) :- not nsup(X), assumption(X).

%% Fill up in(.) with arguments which are defended iteratively

%% ASPARTIX: defended_upto(X,Y) :- inf(Y), arg(X), not att(Y,X).
%% WABA: contrary(X,Y) means Y attacks X
defended_upto(X,Y) :- inf(Y), assumption(X), not contrary(X,Y).

%% ASPARTIX: defended_upto(X,Y) :- inf(Y), in(Z), att(Z,Y), att(Y,X).
%% WABA: Z attacks Y via contrary(Y,Z), Y attacks X via contrary(X,Y)
defended_upto(X,Y) :- inf(Y), in(Z), contrary(Y,Z), contrary(X,Y).

%% ASPARTIX: defended_upto(X,Y) :- succ(Z,Y), defended_upto(X,Z), not att(Y,X).
defended_upto(X,Y) :- succ(Z,Y), defended_upto(X,Z), not contrary(X,Y).

%% ASPARTIX: defended_upto(X,Y) :- succ(Z,Y), defended_upto(X,Z), in(V), att(V,Y), att(Y,X).
%% WABA: V attacks Y via contrary(Y,V), Y attacks X via contrary(X,Y)
defended_upto(X,Y) :- succ(Z,Y), defended_upto(X,Z), in(V), contrary(Y,V), contrary(X,Y).

defended(X) :- sup(Y), defended_upto(X,Y).
in(X) :- defended(X).

%% Grounded = least fixed point, so only defended arguments are in
:- in(X), not defended(X).
