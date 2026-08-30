%% ==========================================================================
%% BETA-SIGMA ADMISSIBLE SEMANTICS
%% ==========================================================================
%% core/base.lp constructs one fixed maximal-context atom-level attack relation,
%% guesses one discard set D, and the selected monoid/bound modules enforce
%% cost(D) beta.  This file contains ONLY ordinary flat-ABA admissibility in the
%% reduced framework Att \ D.  In particular, there is no second `pay` relation
%% and no defence-specific interpretation of beta.

#project in/1.
#project out/1.

1 { in(X); out(X) } 1 :- assumption(X).

%% What the candidate S attacks in the reduced framework.
defeated(Y) :- attacks_successfully_with_weight(_,Y,_).

%% Conflict-freeness.
:- in(Y), defeated(Y).

%% The closure of assumptions not attacked by S represents the arguments that
%% are undefeated by S.  S defends each of its members exactly when no such
%% argument has a surviving attack on that member.
undefeated(X) :- assumption(X), not defeated(X).
undefeated(X) :- head(R,X), undefeated_triggered(R).
undefeated_triggered(R) :- rule(R), undefeated(Z) : body(R,Z).

attacked_by_undefeated(Y) :-
    undefeated(X), attack_survives_with_weight(X,Y,_).

:- in(Y), attacked_by_undefeated(Y).
