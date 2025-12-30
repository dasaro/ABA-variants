%% Staged Semantics (Saturation-Based)
%%
%% Definition: S is staged iff:
%%   1. S is conflict-free, and
%%   2. range(S) is ⊆-maximal among ranges of conflict-free sets
%%
%% Where range(S) = S ∪ S⁺ (assumptions in S or attacked by S)
%%
%% Usage: clingo -n 0 <files> semantics/staged_saturation.lp
%%
%% Approach: Saturation-based maximality check
%% - If not range-maximal (unstable), try to witness a larger conflict-free range
%% - If witness succeeds (spoil=false), reject the extension
%% - If witness fails (spoil=true), accept (extension is maximal)

%% Conflict-freeness
:- in(X), defeated(X).

%% Range: assumptions in extension or defeated
range(X) :- assumption(X), in(X).
range(X) :- assumption(X), defeated(X).

%% Check if range is maximal
out_of_range(X) :- assumption(X), not range(X).
unstable :- out_of_range(_).

%% When unstable, guess a larger range
larger_range(X) : out_of_range(X) :- unstable.
larger_range(X) :- range(X), unstable.

%% For each assumption in larger_range, witness an attack to make it defeated
%% witness(X) means "X is in the larger range and we need to explain why"
%% We must choose either witness(X) or witness(Z) where Z attacks X
witness(X) | witness(Z) : contrary(X,Z) :- larger_range(X), unstable.

%% Check if the witnessed larger range is conflict-free
%% spoil=true if we witness both X and its attacker Y (conflict)
spoil :- witness(X), witness(Y), contrary(Y,X), unstable.

%% If spoiled, saturate to trivialize the constraint
witness(X)      :- spoil, assumption(X), unstable.
larger_range(X) :- spoil, assumption(X), unstable.

%% Reject if we found a larger conflict-free range (unstable but not spoiled)
:- unstable, not spoil.

#show in/1.
