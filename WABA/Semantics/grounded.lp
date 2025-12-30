%% Grounded Semantics
%% Based on ASPforABA implementation (Lehtonen et al. 2021)
%%
%% The grounded extension is the unique minimal (w.r.t. set inclusion) complete extension.
%% Computed via iterative construction: least fixpoint of unattacked assumptions.
%%
%% Usage: clingo -n 1 <files> semantics/grounded.lp
%%        (Use -n 1 since grounded extension is unique)

%% Setup iteration bounds
n_assumptions(N) :- #count{X : assumption(X)} = N.
iteration(0..N) :- n_assumptions(N).

%% Support computation (with iteration tracking)
supported(X,I) :- assumption(X), in(X,I).
supported(X,I) :- head(R,X), triggered_by_in(R,I).
triggered_by_in(R,I) :- iteration(I), head(R,_), supported(X,I) : body(R,X).

%% Conflict freeness (per iteration)
:- in(X,I), contrary(X,Y), supported(Y,I).

%% Defeat tracking (per iteration)
defeated(X,I) :- supported(Y,I), contrary(X,Y).

%% Closure under undefeated (per iteration)
derived_from_undefeated(X,I) :- iteration(I), assumption(X), not defeated(X,I).
derived_from_undefeated(X,I) :- head(R,X), triggered_by_undefeated(R,I).
triggered_by_undefeated(R,I) :- iteration(I), head(R,_), derived_from_undefeated(X,I) : body(R,X).

%% Attacked by undefeated (per iteration)
attacked_by_undefeated(X,I) :- contrary(X,Y), derived_from_undefeated(Y,I).

%% Iterative construction: add unattacked assumptions
in(X,I) :- iteration(J), assumption(X), not attacked_by_undefeated(X,J), J+1=I.

%% Final extension (at fixpoint)
in(X) :- in(X,N), n_assumptions(N).
supported(X) :- supported(X,N), n_assumptions(N).
