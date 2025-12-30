%% Staged Semantics (Saturation-based - EXPERIMENTAL)
%%
%% Based on ASPARTIX saturation approach adapted for ABA
%% Uses saturation to check range-maximality among conflict-free sets
%%
%% Definition: S is staged iff:
%%   1. S is conflict-free, and
%%   2. range(S) is ⊆-maximal among ranges of conflict-free sets
%%
%% Where range(S) = S ∪ S⁺ (assumptions in S or attacked by S)
%%
%% Usage: clingo -n 0 <files> semantics/staged.lp
%%
%% Intuition: "Like semi-stable but dropping admissibility—purely range-maximizing conflict-free sets"
%%
%% WARNING: Current implementation returns UNSATISFIABLE (0 models).
%% The saturation approach conflicts with base.lp's choice-based extension guessing.
%% For production use, use the heuristic-based version (semantics/heuristic/staged.lp).

%% ========================================
%% BASE CONFLICT-FREE EXTENSION
%% ========================================

%% Conflict-freeness
:- in(X), defeated(X).

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
%% CHECK IF S' IS CONFLICT-FREE
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
