#include "cf.lp".

%% Admissibility (CLASSICAL, weight-blind).
%%
%% WABA has TWO orthogonal knobs: the argumentation SEMANTICS (this file) and the
%% inconsistency BUDGET (the discard machinery: monoid + constraint/ub|lb). Defense
%% semantics are the classical ABA notions computed over the attack graph; the budget
%% is NOT folded into the defense reasoning. To reason under a budget, use cf/stable
%% with a monoid + ub/lb; for classical defense (admissible/complete/grounded/preferred)
%% use this family, which pins the discard set to empty (see the constraint below).
%%
%% "defended / undefeated" set: the atoms derivable from the not-defeated assumptions.
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- rule(R), derived_from_undefeated(X) : body(R,X).

%% X is attacked-by-undefeated iff some undefeated element is a contrary (attacker) of X.
%% This is the plain classical condition — every attacker counts, regardless of weight.
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).

%% Admissibility: an IN assumption may not be attacked by an undefeated attacker.
:- in(X), attacked_by_undefeated(X).

%% Defense is classical: the budget/discard knob is off for this family. Pinning the
%% discard set to empty keeps the semantics weight-blind (identical across semirings)
%% and prevents discard-varied duplicate extensions.
:- discarded_attack(_,_,_).
