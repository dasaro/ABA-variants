%% Preferred Semantics
%% Heuristic-based approach: minimize missing assumptions to prefer maximal complete extensions
%%
%% Usage: clingo -n 0 --heuristic=Domain --enum-mode=domRec <files> semantics/preferred.lp
%%
%% Complete: Admissible + contains all defended assumptions
%% Preferred: Maximal complete (w.r.t. set inclusion)
%%
%% Approach: Use domain heuristics to prefer models with fewer OUT assumptions

%% Conflict-freeness
:- in(X), defeated(X).

%% Compute closure under undefeated assumptions
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).

%% Attacked by undefeated assumptions (respecting budget-based attack discarding)
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y), supported(Y), not discarded_attack(Y,X,_).
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y), assumption(Y), not supported(Y).

%% Admissibility: in assumptions must not be attacked by undefeated
:- in(X), attacked_by_undefeated(X).

%% Completeness: All unattacked (defended) assumptions must be in
:- out(X), not attacked_by_undefeated(X).

%% Track missing assumptions
miss(X) :- assumption(X), not in(X).

%% Heuristic: prefer models with fewer missing assumptions (prefer including assumptions)
%% This should guide the solver toward subset-maximal complete extensions
#heuristic miss(X) : assumption(X). [1,false]
