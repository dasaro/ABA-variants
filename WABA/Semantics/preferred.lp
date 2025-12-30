%% Preferred Semantics (Saturation-based - EXPERIMENTAL)
%%
%% Based on ASPARTIX prefex_gringo.lp adapted for ABA
%% Uses saturation approach with successor ordering for subset-maximality
%%
%% Definition: Maximal (w.r.t. set inclusion) complete extensions
%%
%% Usage: clingo -n 0 <files> semantics/preferred.lp
%%
%% WARNING: Current implementation returns ALL complete extensions, not just maximal ones.
%% The maximality check is not working correctly yet. For production use, consider using
%% the heuristic-based version (semantics/heuristic/preferred.lp) instead.
%%
%% Approach: For each complete extension S, guess a superset S' and check if S'
%% is also complete. If S' = S (no strict superset exists), accept. Otherwise spoil.

%% ========================================
%% DISJUNCTIVE GUESS FOR BASE EXTENSION
%% ========================================

%% Each assumption is either defended or defeated (or both)
defended(X) | defeated(X) :- assumption(X).

%% If defended and not defeated, it's in the extension
in(X) :- defended(X), not defeated(X).

%% Everything else is out
out(X) :- assumption(X), not in(X).

%% ========================================
%% COMPUTE ACTUAL SUPPORT AND ATTACKS
%% ========================================

%% Actual defeat: assumption is defeated if something supported attacks it
actually_defeated(X) :- assumption(X), supported(Y), contrary(X,Y).

%% Compute what's derivable from undefeated assumptions (for completeness)
derived_from_undefeated(X) :- assumption(X), not actually_defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).

%% Attacked by undefeated: used for completeness check
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).

%% Actually defended: NOT attacked by anything from undefeated
actually_defended(X) :- assumption(X), not attacked_by_undefeated(X).

%% ========================================
%% CONSISTENCY CONSTRAINTS (COMPLETENESS)
%% ========================================

%% Conflict-freeness: if in, must not be actually defeated
:- in(X), actually_defeated(X).

%% Admissibility: in assumptions must not be attacked by undefeated
:- in(X), attacked_by_undefeated(X).

%% Completeness: if actually defended, must be in
:- actually_defended(X), out(X).

%% Coherence: if guessed defended, must match actual defense
:- defended(X), not actually_defended(X).
:- actually_defended(X), not defended(X).

%% ========================================
%% ORDERING ON ASSUMPTIONS FOR SATURATION
%% ========================================

%% Create ordering: X < Y if assumption names compare lexicographically
lt(X,Y) :- assumption(X), assumption(Y), X < Y.

%% Successor relation: succ(X,Y) means Y is immediate successor of X
nsucc(X,Z) :- lt(X,Y), lt(Y,Z).
succ(X,Y) :- lt(X,Y), not nsucc(X,Y).

%% Infimum and supremum
ninf(X) :- lt(Y,X).
nsup(X) :- lt(X,Y).
inf(X) :- not ninf(X), assumption(X).
sup(X) :- not nsup(X), assumption(X).

%% ========================================
%% GUESS SUPERSET EXTENSION S'
%% ========================================

%% S' must contain S (all in assumptions stay in)
inN(X) :- in(X).

%% For out assumptions, guess if they go in S'
inN(X) | outN(X) :- out(X).

%% ========================================
%% CHECK IF S' = S (using ordering)
%% ========================================

%% Track equality up to each position in ordering
eq_upto(Y) :- inf(Y), in(Y), inN(Y).
eq_upto(Y) :- inf(Y), out(Y), outN(Y).

eq_upto(Y) :- succ(Z,Y), in(Y), inN(Y), eq_upto(Z).
eq_upto(Y) :- succ(Z,Y), out(Y), outN(Y), eq_upto(Z).

%% S' = S if equality holds up to supremum
eq :- sup(Y), eq_upto(Y).

%% ========================================
%% CHECK IF S' IS COMPLETE
%% ========================================

%% Recompute support for S' (what's derivable from inN assumptions)
supportedN(X) :- assumption(X), inN(X).
supportedN(X) :- head(R,X), triggered_by_inN(R).
triggered_by_inN(R) :- head(R,_), supportedN(X) : body(R,X).

%% Compute what's defeated in S' (attacked by something supported in S')
defeatedN(X) :- assumption(X), supportedN(Y), contrary(X,Y).

%% Compute what's derivable from assumptions not defeated in S'
derived_from_undefeatedN(X) :- assumption(X), not defeatedN(X).
derived_from_undefeatedN(X) :- head(R,X), triggered_by_undefeatedN(R).
triggered_by_undefeatedN(R) :- head(R,_), derived_from_undefeatedN(X) : body(R,X).

%% Attacked by undefeated in S'
attacked_by_undefeatedN(X) :- contrary(X,Y), derived_from_undefeatedN(Y).

%% Actually defended in S'
actually_defendedN(X) :- assumption(X), not attacked_by_undefeatedN(X).

%% Actually defeated in S' (for conflict-freeness check)
actually_defeatedN(X) :- defeatedN(X).

%% ========================================
%% SPOIL CONDITIONS
%% ========================================

%% Spoil if S' = S (no proper superset, so S is maximal - but we're looking for non-maximal!)
spoil_eq :- eq.
spoil :- spoil_eq.

%% Spoil if S' is not conflict-free
spoil_cf :- inN(X), actually_defeatedN(X).
spoil :- spoil_cf.

%% Spoil if S' is not admissible
spoil_adm :- inN(X), attacked_by_undefeatedN(X).
spoil :- spoil_adm.

%% Spoil if S' is not complete
spoil_comp :- actually_defendedN(X), outN(X).
spoil :- spoil_comp.

%% If spoiled, make everything in/out to collapse the domain
inN(X) :- spoil, assumption(X).
outN(X) :- spoil, assumption(X).

%% ========================================
%% REJECT IF NOT SPOILED
%% ========================================

%% If we found a proper superset that's complete, then S is not maximal
:- not spoil.

#show in/1.
