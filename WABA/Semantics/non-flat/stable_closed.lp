%% Stable Semantics with Closure Constraint (Non-Flat ABA)
%% Based on ASPforABA IJCAI'24 implementation
%%
%% Extension must be:
%% 1. Conflict-free
%% 2. Closed: all assumptions derived from the extension must be in
%% 3. Stable: all out assumptions must be defeated
%%
%% Usage: clingo -n 0 <files> semantics/stable_closed.lp

%% Assumption is either in or out
in(X) :- assumption(X), not out(X).
out(X) :- assumption(X), not in(X).

%% Compute what is derived from the extension
derived(X) :- assumption(X), in(X).
derived(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), derived(X) : body(R,X).

%% Conflict-freeness
:- in(X), contrary(X,Y), derived(Y).

%% Closure constraint: all derived assumptions must be in
:- assumption(X), derived(X), not in(X).

%% Defeat tracking
defeated(X) :- derived(Y), contrary(X,Y).

%% Stability: all out assumptions must be defeated
:- out(X), not defeated(X).
