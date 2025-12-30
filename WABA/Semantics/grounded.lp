%% Grounded Semantics - Least Fixpoint Approach
%% Based on ASPforABA (Lehtonen et al. 2021)
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

%% Grounded extension as least fixpoint
%% An assumption is defeated if a grounded assumption attacks it
g_defeated(X) :- assumption(X), g_in(Y), contrary(X,Y).

%% An assumption is in the grounded extension if it defeats all its attackers
%% (i.e., all assumptions with this one as contrary are defeated)
g_in(X) :- assumption(X), g_defeated(Y) : contrary(X,Y).

%% Enforce that the guessed in/1 (from core/base.lp) matches grounded exactly
:- g_in(X), not in(X).  % If in grounded, must be in extension
:- in(X), not g_in(X).  % If in extension, must be in grounded

#show in/1.
