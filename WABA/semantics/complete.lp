%% ==========================================================================
%% BETA-SIGMA COMPLETE SEMANTICS
%% ==========================================================================
%% Complete extensions are precisely the ordinary complete extensions of the
%% same reduced framework Att \ D used by every other supported semantics.

#include "admissible.lp".

%% An assumption is defended when no undefeated argument has a surviving attack
%% on it.  Completeness requires every defended assumption to belong to S.
:- out(Y), not attacked_by_undefeated(Y).
