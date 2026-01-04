%% Ideal Semantics
%% ===============
%%
%% Definition: The unique maximal admissible extension contained in all preferred extensions
%%
%% Semantic: Represents the "skeptically acceptable" arguments under preferred semantics
%%           Always contains the grounded extension
%%           Always contained in all preferred extensions
%%
%% Properties:
%%   - Unique (always exactly one ideal extension)
%%   - grounded ⊆ ideal ⊆ ∩(all preferred)
%%
%% Implementation: Iterative fixed-point computation
%%   - Start from grounded extension (minimal complete)
%%   - Iteratively add assumptions acceptable w.r.t. current set
%%   - Stop when fixed point reached
%%
%% Usage:
%%   clingo -n 1 WABA/core/base.lp WABA/semiring/godel.lp \
%%          WABA/monoid/max_minimization.lp WABA/filter/standard.lp \
%%          WABA/semantics/ideal.lp framework.lp
%%
%% Note: Use -n 1 (exactly one model) since ideal is unique
%%
%% Expected for test/aspforaba_journal_example.lp with beta=0: {a}

#include "cf.lp".

%% Compute grounded extension first (minimal complete)
g_defeated(X) :- assumption(X), g_in(Y), contrary(X,Y).
g_in(X) :- assumption(X), g_defeated(Y) : contrary(X,Y).

%% Ideal extension iterative computation
%% i_in(X) represents assumptions in the ideal extension
%% Base: Start with grounded extension
i_in(X) :- g_in(X).

%% Iterative step: Add assumptions acceptable w.r.t. current ideal
%% An assumption X is acceptable if all its attackers are defeated by i_in
i_defeated(Y) :- assumption(Y), i_in(X), contrary(Y,X).
i_acceptable(X) :- assumption(X), i_defeated(Y) : contrary(X,Y).

%% Add acceptable assumptions to ideal (fixed-point)
i_in(X) :- i_acceptable(X), assumption(X).

%% The extension must match the ideal extension
:- i_in(X), not in(X).
:- in(X), not i_in(X).

#show in/1.
