%% Complete Semantics
%% Builds upon: Admissible
%%
%% An extension is complete if it is admissible and contains all assumptions it defends.
%%
%% Complete: Admissible + for every assumption X that is defended, X must be in

#include "admissible.lp".

%% Completeness: All defended assumptions must be in
:- out(X), assumption(X), not not_defended(X).
