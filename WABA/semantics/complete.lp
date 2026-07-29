%% ============================================================================
%% wABA BUDGETED COMPLETE — Dunne Def 6 lift of complete semantics.
%% ============================================================================
%% A complete extension is a budgeted-admissible S that contains every assumption it
%% DEFENDS in the reduced framework (attacks minus `pay`): if Y has no surviving
%% reduced-undefeated attacker, Y must be in. beta = 0 recovers classical complete.

#include "admissible.lp".

%% Y is attacked in the reduced framework iff some surviving (unpaid) reduced-undefeated
%% argument is its contrary. A defended assumption is one with no such attacker.
attacked_reduced(Y) :- assumption(Y), contrary(Y,X), runde(X), not pay(X,Y).
:- out(Y), assumption(Y), not attacked_reduced(Y).
