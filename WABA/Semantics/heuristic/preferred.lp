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

%% Admissibility: X must be defended against all attackers (actual and potential)
%% Case 1: Y is an assumption - potential attacker even if OUT
not_defended(X) :- contrary(X,Y), assumption(Y), not defeated(Y), not discarded_attack(Y,X,_).
%% Case 2: Y is supported - actual attacker (covers derived elements and IN assumptions)
not_defended(X) :- contrary(X,Y), supported(Y), not defeated(Y), not discarded_attack(Y,X,_).

%% Admissibility: in assumptions must not be attacked by undefeated
:- in(X), not_defended(X).

%% Completeness: All defended assumptions must be in
:- out(X), assumption(X), not not_defended(X).

%% Track missing assumptions
miss(X) :- assumption(X), not in(X).

%% Heuristic: prefer models with fewer missing assumptions (prefer including assumptions)
%% This should guide the solver toward subset-maximal complete extensions
#heuristic miss(X) : assumption(X). [1,false]
