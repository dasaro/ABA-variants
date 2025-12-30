%% Ideal Semantics (Saturation-Based)
%%
%% Definition: The ideal extension I is the unique set such that:
%%   1. I is admissible
%%   2. I ⊆ E for every preferred extension E (I ⊆ ⋂Pref(F))
%%   3. I is ⊆-maximal with properties (1)–(2)
%%
%% Equivalently: I is the greatest admissible subset of ⋂Pref(F)
%%
%% Usage: clingo -n 1 <files> semantics/ideal.lp
%%
%% Approach: Two-phase saturation
%% - Phase 1: Determine which assumptions are in ALL preferred extensions
%% - Phase 2: Find maximal admissible subset of those assumptions

%% ========================================
%% ADMISSIBILITY (Current Extension)
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

%% ========================================
%% PHASE 1: INTERSECTION OF PREFERRED
%% ========================================

%% Guess which assumptions are NOT in intersection of all preferred
{ not_in_intersection(X) : assumption(X) }.

%% For each X NOT in intersection, witness a complete extension without X
{ witness(X, Y) : assumption(Y) } :- not_in_intersection(X).

%% X must not be in witness
:- not_in_intersection(X), witness(X, X).

%% Witness must be complete
%% Compute what's supported in witness
supported_w(X, A) :- assumption(A), witness(X, A).
supported_w(X, B) :- head(R,B), triggered_w(X, R).
triggered_w(X, R) :- head(R,_), not_in_intersection(X), supported_w(X, Y) : body(R,Y).

%% Compute attacks in witness
attacks_w(X, A, B) :- supported_w(X, A), assumption(B), contrary(B, A).
defeated_w(X, A) :- attacks_w(X, _, A), assumption(A).

%% Witness must be conflict-free
:- not_in_intersection(X), witness(X, A), defeated_w(X, A).

%% Compute undefeated closure for admissibility
undefeated_w(X, A) :- assumption(A), not_in_intersection(X), not defeated_w(X, A).
undefeated_w(X, B) :- head(R,B), triggered_undefeated_w(X, R).
triggered_undefeated_w(X, R) :- head(R,_), not_in_intersection(X), undefeated_w(X, Y) : body(R,Y).

attacked_by_undefeated_w(X, A) :- contrary(A,B), undefeated_w(X, B).

%% Witness must be admissible
:- not_in_intersection(X), witness(X, A), attacked_by_undefeated_w(X, A).

%% Compute defended assumptions
defended_w(X, A) :- assumption(A), not_in_intersection(X), defeated_w(X, B) : contrary(A,B).

%% Witness must be complete: all defended must be in
:- not_in_intersection(X), defended_w(X, A), not witness(X, A).

%% Witness must be maximal (preferred)
%% For each missing assumption, try to add it
miss_w(X, A) :- assumption(A), not_in_intersection(X), not witness(X, A).
has_miss_w(X) :- miss_w(X, _), not_in_intersection(X).

%% If no missing assumptions, witness is already maximal
witness_maximal(X) :- not_in_intersection(X), not has_miss_w(X).

%% Otherwise, try to extend and show it fails
{ try_extend_w(X, A) : miss_w(X, A) } :- has_miss_w(X).

%% At least one extension attempt
:- has_miss_w(X), { try_extend_w(X, A) : miss_w(X, A) } = 0.

%% Extended witness
extended_w(X, A) :- witness(X, A), has_miss_w(X).
extended_w(X, A) :- try_extend_w(X, A), has_miss_w(X).

%% Check if extended witness is complete
supported_ext_w(X, A) :- assumption(A), extended_w(X, A).
supported_ext_w(X, B) :- head(R,B), triggered_ext_w(X, R).
triggered_ext_w(X, R) :- head(R,_), has_miss_w(X), supported_ext_w(X, Y) : body(R,Y).

attacks_ext_w(X, A, B) :- supported_ext_w(X, A), assumption(B), contrary(B, A).
defeated_ext_w(X, A) :- attacks_ext_w(X, _, A), assumption(A).

undefeated_ext_w(X, A) :- assumption(A), has_miss_w(X), not defeated_ext_w(X, A).
undefeated_ext_w(X, B) :- head(R,B), triggered_undefeated_ext_w(X, R).
triggered_undefeated_ext_w(X, R) :- head(R,_), has_miss_w(X), undefeated_ext_w(X, Y) : body(R,Y).

attacked_by_undefeated_ext_w(X, A) :- contrary(A,B), undefeated_ext_w(X, B).
defended_ext_w(X, A) :- assumption(A), has_miss_w(X), defeated_ext_w(X, B) : contrary(A,B).

%% Extension fails if not complete
extension_fails(X) :- has_miss_w(X), extended_w(X, A), defeated_ext_w(X, A).
extension_fails(X) :- has_miss_w(X), extended_w(X, A), attacked_by_undefeated_ext_w(X, A).
extension_fails(X) :- has_miss_w(X), defended_ext_w(X, A), not extended_w(X, A).

%% If all extensions fail, witness is maximal
witness_maximal(X) :- has_miss_w(X), extension_fails(X).

%% Require witness to be maximal (preferred)
:- not_in_intersection(X), not witness_maximal(X).

%% ========================================
%% IDEAL CONSTRAINT
%% ========================================

%% Ideal can only contain assumptions in intersection of all preferred
:- in(X), not_in_intersection(X).

%% ========================================
%% SUBSET-MAXIMALITY
%% ========================================

%% Maximize among admissible sets contained in intersection
in_intersection(X) :- assumption(X), not not_in_intersection(X).
miss(X) :- assumption(X), not in(X), in_intersection(X).
unstable :- miss(_).

larger_ext(X) : miss(X) :- unstable.
larger_ext(X) :- in(X), unstable.
:- unstable, { larger_ext(X) : miss(X) } = 0.

%% Check if larger_ext is admissible
supported_larger(X) :- assumption(X), larger_ext(X).
supported_larger(X) :- head(R,X), triggered_larger(R).
triggered_larger(R) :- head(R,_), supported_larger(X) : body(R,X).

attacks_larger(X,Y) :- supported_larger(X), assumption(Y), contrary(Y,X).
defeated_larger(X) :- attacks_larger(_,X), assumption(X).

spoil :- larger_ext(X), defeated_larger(X), unstable.

undefeated_larger(X) :- assumption(X), not defeated_larger(X).
undefeated_larger(X) :- head(R,X), triggered_undefeated_larger(R).
triggered_undefeated_larger(R) :- head(R,_), undefeated_larger(X) : body(R,X).

attacked_by_undefeated_larger(X) :- contrary(X,Y), undefeated_larger(Y).
spoil :- larger_ext(X), attacked_by_undefeated_larger(X), unstable.

larger_ext(X) :- spoil, assumption(X), unstable.
:- unstable, not spoil.

#show in/1.
