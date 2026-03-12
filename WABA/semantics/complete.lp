%% Complete Semantics
%% Builds upon: Admissible

#include "admissible.lp".

%% Completeness: All unattacked assumptions must be IN
%% If an assumption is not attacked by any undefeated element, it must be in the extension
:- out(X), assumption(X), not attacked_by_undefeated(X).

