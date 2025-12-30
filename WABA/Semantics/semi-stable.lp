%% Semi-Stable Semantics (Saturation-based - EXPERIMENTAL)
%%
%% Based on ASPARTIX saturation approach adapted for ABA
%% Uses saturation to check range-maximality among admissible sets
%%
%% Definition: S is semi-stable iff:
%%   1. S is admissible, and
%%   2. range(S) is ⊆-maximal among ranges of admissible sets
%%
%% Where range(S) = S ∪ S⁺ (assumptions in S or attacked by S)
%%
%% Usage: clingo -n 0 <files> semantics/semi-stable.lp
%%
%% WARNING: Current implementation returns UNSATISFIABLE (0 models).
%% The saturation approach conflicts with base.lp's choice-based extension guessing.
%% For production use, use the heuristic-based version (semantics/heuristic/semi-stable.lp).

%% ========================================
%% BASE ADMISSIBLE EXTENSION
%% ========================================

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

%% Range of base extension: assumptions in S or defeated by S
in_range(X) :- assumption(X), in(X).
in_range(X) :- assumption(X), defeated(X).

%% ========================================
%% ORDERING FOR SATURATION
%% ========================================

lt(X,Y) :- assumption(X), assumption(Y), X < Y.
nsucc(X,Z) :- lt(X,Y), lt(Y,Z).
succ(X,Y) :- lt(X,Y), not nsucc(X,Y).
ninf(X) :- lt(Y,X).
nsup(X) :- lt(X,Y).
inf(X) :- not ninf(X), assumption(X).
sup(X) :- not nsup(X), assumption(X).

%% ========================================
%% GUESS SUPERSET S' ⊇ S
%% ========================================

inN(X) :- in(X).
inN(X) | outN(X) :- out(X).

%% ========================================
%% CHECK IF S' IS ADMISSIBLE
%% ========================================

%% Recompute support for S'
supportedN(X) :- assumption(X), inN(X).
supportedN(X) :- head(R,X), triggered_by_inN(R).
triggered_by_inN(R) :- head(R,_), supportedN(X) : body(R,X).

%% Defeated in S'
defeatedN(X) :- assumption(X), supportedN(Y), contrary(X,Y).

%% Conflict-freeness of S'
spoil_cf :- inN(X), defeatedN(X).
spoil :- spoil_cf.

%% Undefeated closure in S'
derived_from_undefeatedN(X) :- assumption(X), not defeatedN(X).
derived_from_undefeatedN(X) :- head(R,X), triggered_by_undefeatedN(R).
triggered_by_undefeatedN(R) :- head(R,_), derived_from_undefeatedN(X) : body(R,X).

attacked_by_undefeatedN(X) :- contrary(X,Y), derived_from_undefeatedN(Y).

%% Admissibility of S'
spoil_adm :- inN(X), attacked_by_undefeatedN(X).
spoil :- spoil_adm.

%% ========================================
%% COMPARE RANGES
%% ========================================

%% Range of S'
in_rangeN(X) :- assumption(X), inN(X).
in_rangeN(X) :- assumption(X), defeatedN(X).

%% Check if range(S') = range(S) using ordering
range_eq_upto(Y) :- inf(Y), in_range(Y), in_rangeN(Y).
range_eq_upto(Y) :- inf(Y), not in_range(Y), not in_rangeN(Y).

range_eq_upto(Y) :- succ(Z,Y), in_range(Y), in_rangeN(Y), range_eq_upto(Z).
range_eq_upto(Y) :- succ(Z,Y), not in_range(Y), not in_rangeN(Y), range_eq_upto(Z).

range_eq :- sup(Y), range_eq_upto(Y).

%% Spoil if ranges are equal (no improvement, so S is range-maximal)
spoil_range_eq :- range_eq.
spoil :- spoil_range_eq.

%% ========================================
%% SATURATION COLLAPSE
%% ========================================

inN(X) :- spoil, assumption(X).
outN(X) :- spoil, assumption(X).

%% ========================================
%% REJECT IF NOT SPOILED
%% ========================================

%% If we found larger range, S is not range-maximal
:- not spoil.

#show in/1.
