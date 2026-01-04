%% Grounded Semantics
%% Minimal complete extension (least fixpoint)
%%
%% Based on characteristic function: assumption is IN if it defeats all attackers
%% Compatible with WABA's choice-based architecture via constraint matching

#include "cf.lp".

%% Compute grounded extension via fixpoint
g_defeated(X) :- assumption(X), g_in(Y), contrary(X,Y).
g_in(X) :- assumption(X), g_defeated(Y) : contrary(X,Y).

%% Constrain choice-based in/1 to match grounded
:- g_in(X), not in(X).
:- in(X), not g_in(X).
