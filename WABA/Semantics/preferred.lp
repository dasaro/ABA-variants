%% Preferred Semantics
%% NOTE: This is currently equivalent to complete semantics.
%% Filtering to maximal (subset-maximal) extensions requires external processing.
%%
%% In pure ASP, preferred semantics for ABA requires complex encodings or multi-shot solving.
%% ASPforABA uses Python callbacks for refinement (see _ee_pref in aba_solver.py).
%%
%% For WABA testing: Generate all complete extensions, then filter to subset-maximal ones externally.
%%
%% Usage: clingo -n 0 <files> semantics/preferred.lp
%%
%% Complete: Admissible + contains all defended assumptions
%% Preferred: Maximal complete (w.r.t. set inclusion)

%% Conflict-freeness
:- in(X), defeated(X).

%% Compute closure under undefeated assumptions
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).

%% Attacked by undefeated assumptions
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).

%% Admissibility: in assumptions must not be attacked by undefeated
:- in(X), attacked_by_undefeated(X).

%% Completeness: All unattacked (defended) assumptions must be in
:- out(X), not attacked_by_undefeated(X).

%% TODO: Implement subset-maximality check in pure ASP
%% For now, this generates complete extensions only
