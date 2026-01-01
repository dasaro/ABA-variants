%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% SEMI-STABLE SEMANTICS (SATURATION, NO WEAK CONSTRAINTS)
%%
%% Semi-stable = complete extensions with maximal range
%% Range = assumptions in extension OR attacked by extension
%%
%% Uses saturation: rejects extensions where a witness has strictly larger range
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#include "cf.lp".

%% -------------------------------------------------------------------------
%% Use successful attacks (after discarding) for completeness and range
%% -------------------------------------------------------------------------
att(A,B) :- attacks_successfully_with_weight(A,B,_).

%% -------------------------------------------------------------------------
%% Primary candidate extension (choice over assumptions)
%% Note: out/1 is already defined in core/base.lp
%% -------------------------------------------------------------------------
{ in(X) } :- assumption(X).

%% Attacked-by-extension (for range calculation)
attacked(Y) :- in(X), att(X,Y).

%% Defense: X is defended if every attacker of X is attacked
undefended(X) :- att(Y,X), not attacked(Y).
defended(X) :- assumption(X), not undefended(X).

%% Admissible
:- in(X), not defended(X).

%% Complete: include all defended arguments
:- out(X), defended(X).

%% Range of the extension
range(X) :- in(X).
range(X) :- attacked(X).

%% -------------------------------------------------------------------------
%% Witness extension in2/out2 (another COMPLETE extension)
%% -------------------------------------------------------------------------
{ in2(X) } :- assumption(X).
out2(X) :- assumption(X), not in2(X).

%% Conflict-free (witness) - use defeated/1 from core/base.lp
:- in2(X), defeated(X).

%% Attacked-by-witness (for range calculation)
attacked2(Y) :- in2(X), att(X,Y).

%% Defense (witness)
undefended2(X) :- att(Y,X), not attacked2(Y).
defended2(X) :- assumption(X), not undefended2(X).

%% Admissible (witness)
:- in2(X), not defended2(X).

%% Complete (witness)
:- out2(X), defended2(X).

%% Range (witness)
range2(X) :- in2(X).
range2(X) :- attacked2(X).

%% -------------------------------------------------------------------------
%% "Better witness" = witness has a STRICTLY larger range than current range
%%
%% Superset check:
%%   bad_witness if current range contains something not in witness range.
%% Strictness:
%%   witness adds at least one element not in current range.
%% -------------------------------------------------------------------------
bad_witness :- range(X), not range2(X).

adds_new :- range2(X), not range(X).

better_witness :- not bad_witness, adds_new.

%% Semi-stable condition: forbid existence of a better witness
:- better_witness.

#project in/1.
#show in/1.
