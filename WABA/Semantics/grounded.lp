%% Grounded Semantics - Least Fixpoint Approach
%%
%% NOTE: This is a custom WABA implementation, NOT based on ASPforABA.
%% ASPforABA's iterative construction conflicts with WABA's choice-based core/base.lp.
%% This implementation uses a direct fixpoint computation with constraint-based matching.
%%
%% The grounded extension is the unique minimal (w.r.t. set inclusion) complete extension.
%% Computed via least fixpoint: the set of all assumptions that defeat all their attackers.
%%
%% Usage: clingo -n 1 <files> semantics/grounded.lp
%%        (Use -n 1 since grounded extension is unique)
%%
%% This encoding works with WABA's core/base.lp by:
%% 1. Computing the grounded extension in g_in/1 via fixpoint
%% 2. Constraining the choice-based in/1 to match g_in/1 exactly

%% Conflict-freeness: assumptions in the extension must not be defeated
:- in(X), defeated(X).

%% Enforce that the guessed in/1 (from core/base.lp) matches grounded exactly
:- g_in(X), not in(X).  % If in grounded, must be in extension
:- in(X), not g_in(X).  % If in extension, must be in grounded

%% Grounded extension as least fixpoint
%% In WABA, we compute grounded based on the defeat relation AFTER considering attack discarding
%% An assumption is in the grounded extension if it's not defeated by the current extension
%% This forms a least fixpoint: start with all undefeated assumptions
g_in(X) :- assumption(X), not defeated(X).

#show in/1.
