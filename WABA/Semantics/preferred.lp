%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% PREFERRED SEMANTICS (SATURATION, NO WEAK CONSTRAINTS)
%%
%% Preferred = maximal (⊇) complete extensions
%%
%% Uses saturation: rejects extensions where a witness has strictly larger size
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#include "cf.lp".

%% -------------------------------------------------------------------------
%% Use successful attacks (after discarding) for completeness checking
%% -------------------------------------------------------------------------
att(A,B) :- attacks_successfully_with_weight(A,B,_).

%% -------------------------------------------------------------------------
%% Primary candidate extension (choice over assumptions)
%% Note: out/1 is already defined in core/base.lp
%% -------------------------------------------------------------------------
{ in(X) } :- assumption(X).

%% Attacked-by-extension (for defense checking)
attacked(Y) :- in(X), att(X,Y).

%% Defense: X is defended if every attacker of X is attacked
undefended(X) :- att(Y,X), not attacked(Y).
defended(X) :- assumption(X), not undefended(X).

%% Admissible
:- in(X), not defended(X).

%% Complete: include all defended arguments
:- out(X), defended(X).

%% -------------------------------------------------------------------------
%% Witness extension in2/out2 (another COMPLETE extension)
%% -------------------------------------------------------------------------
{ in2(X) } :- assumption(X).
out2(X) :- assumption(X), not in2(X).

%% Conflict-free (witness) - use defeated/1 from core/base.lp
:- in2(X), defeated(X).

%% Attacked-by-witness (for defense checking)
attacked2(Y) :- in2(X), att(X,Y).

%% Defense (witness)
undefended2(X) :- att(Y,X), not attacked2(Y).
defended2(X) :- assumption(X), not undefended2(X).

%% Admissible (witness)
:- in2(X), not defended2(X).

%% Complete (witness)
:- out2(X), defended2(X).

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

%% Preferred condition: forbid existence of a better witness
:- better_witness.

#project in/1.
#show in/1.
