%% Staged Semantics
%%
%% Definition: S is staged iff:
%%   1. S is conflict-free, and
%%   2. range(S) is ⊆-maximal among ranges of conflict-free sets
%%
%% Where range(S) = S ∪ S⁺ (assumptions in S or attacked by S)
%%
%% Usage: clingo -n 0 --opt-mode=optN <files> semantics/staged.lp
%%        (use optN to enumerate all range-maximal extensions)
%%
%% Intuition: "Like semi-stable but dropping admissibility—purely range-maximizing conflict-free sets"

%% Conflict-freeness
:- in(X), defeated(X).

%% Range: assumptions that are in the extension OR defeated by it
%% range(S) = S ∪ S⁺
in_range(X) :- assumption(X), in(X).
in_range(X) :- assumption(X), defeated(X).

%% Maximize range (minimize assumptions not in range)
%% Use weak constraint to prefer extensions with larger ranges
:~ not in_range(X), assumption(X). [1,X]
