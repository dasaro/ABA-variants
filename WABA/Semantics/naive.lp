%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% NAIVE SEMANTICS (SATURATION, NO WEAK CONSTRAINTS)
%%
%% Naive = maximal (⊇) conflict-free extensions
%%
%% Uses saturation: rejects extensions where a witness has strictly larger size
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#include "cf.lp".

%% -------------------------------------------------------------------------
%% Use successful attacks (after discarding) for conflict-free checking
%% -------------------------------------------------------------------------
att(A,B) :- attacks_successfully_with_weight(A,B,_).

%% -------------------------------------------------------------------------
%% Primary candidate extension (choice over assumptions)
%% Note: out/1 is already defined in core/base.lp
%% -------------------------------------------------------------------------
{ in(X) } :- assumption(X).

%% -------------------------------------------------------------------------
%% Witness extension in2/out2 (another CONFLICT-FREE extension)
%% -------------------------------------------------------------------------
{ in2(X) } :- assumption(X).
out2(X) :- assumption(X), not in2(X).

%% Conflict-free (witness) - use defeated/1 from core/base.lp
:- in2(X), defeated(X).

%% -------------------------------------------------------------------------
%% "Better witness" = witness has STRICTLY more assumptions than current
%%
%% Superset check:
%%   bad_witness if witness misses something in current extension.
%% Strictness:
%%   witness adds at least one assumption not in current extension.
%% -------------------------------------------------------------------------
bad_witness :- in(X), not in2(X).

adds_new :- in2(X), not in(X).

better_witness :- not bad_witness, adds_new.

%% Naive condition: forbid existence of a better witness
:- better_witness.

#project in/1.
#show in/1.
