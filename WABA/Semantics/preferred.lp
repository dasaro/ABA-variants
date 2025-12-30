%% Preferred Semantics (Saturation-Based)
%%
%% Definition: Maximal (w.r.t. set inclusion) complete extensions
%%
%% Usage: clingo -n 0 <files> semantics/preferred_saturation.lp
%%
%% Approach: Saturation-based subset-maximality check
%% - If not ⊆-maximal (unstable), try to witness a strictly larger complete extension
%% - If witness succeeds (spoil=false), reject the extension
%% - If witness fails (spoil=true), accept (extension is maximal)

%% ========================================
%% COMPLETENESS (Current Extension)
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

%% Defended assumptions: all attackers are defeated
defended(X) :- assumption(X), defeated(Y) : contrary(X,Y).

%% Completeness: all defended assumptions must be in
:- defended(X), not in(X).

%% ========================================
%% SUBSET-MAXIMALITY CHECK
%% ========================================

%% Check if subset-maximal
miss(X) :- assumption(X), not in(X).
unstable :- miss(_).

%% When unstable, guess a strictly larger extension
larger_ext(X) : miss(X) :- unstable.
larger_ext(X) :- in(X), unstable.

%% Ensure larger_ext is strictly larger (at least one miss assumption added)
:- unstable, { larger_ext(X) : miss(X) } = 0.

%% ========================================
%% COMPLETENESS CHECK FOR LARGER_EXT
%% ========================================

%% Compute what's supported under larger_ext
supported_larger(X) :- assumption(X), larger_ext(X).
supported_larger(X) :- head(R,X), triggered_larger(R).
triggered_larger(R) :- head(R,_), supported_larger(X) : body(R,X).

%% Compute attacks under larger_ext
attacks_larger(X,Y) :- supported_larger(X), assumption(Y), contrary(Y,X).

%% Compute what's defeated under larger_ext
defeated_larger(X) :- attacks_larger(_,X), assumption(X).

%% Conflict-freeness check for larger_ext
%% spoil=true if larger_ext is not conflict-free
spoil :- larger_ext(X), defeated_larger(X), unstable.

%% Compute undefeated closure for larger_ext (for admissibility check)
derived_undefeated_larger(X) :- assumption(X), not defeated_larger(X).
derived_undefeated_larger(X) :- head(R,X), triggered_undefeated_larger(R).
triggered_undefeated_larger(R) :- head(R,_), derived_undefeated_larger(X) : body(R,X).

%% Compute attacks by undefeated under larger_ext
attacked_by_undefeated_larger(X) :- contrary(X,Y), derived_undefeated_larger(Y).

%% Admissibility check for larger_ext
%% spoil=true if larger_ext is not admissible (contains attacked-by-undefeated assumption)
spoil :- larger_ext(X), attacked_by_undefeated_larger(X), unstable.

%% Defended assumptions under larger_ext
defended_larger(X) :- assumption(X), defeated_larger(Y) : contrary(X,Y).

%% Completeness check for larger_ext
%% spoil=true if larger_ext is not complete (misses a defended assumption)
spoil :- defended_larger(X), not larger_ext(X), unstable.

%% ========================================
%% SATURATION AND CONSTRAINT
%% ========================================

%% Saturation: if spoiled, make all assumptions part of larger_ext
larger_ext(X) :- spoil, assumption(X), unstable.

%% Reject if we found a valid larger complete extension (unstable but not spoiled)
:- unstable, not spoil.

#show in/1.
