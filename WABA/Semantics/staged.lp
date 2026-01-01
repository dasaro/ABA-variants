%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% STAGED SEMANTICS (SATURATION, NO WEAK CONSTRAINTS)
%%
%% Staged = conflict-free extensions with maximal range
%% Range = assumptions in extension OR defeated by extension
%%
%% Uses saturation: rejects extensions where a witness has strictly larger range
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

#include "cf.lp".

%% -------------------------------------------------------------------------
%% Use successful attacks (after discarding) for conflict-free and range
%% -------------------------------------------------------------------------
att(A,B) :- attacks_successfully_with_weight(A,B,_).

%% -------------------------------------------------------------------------
%% Primary candidate extension (choice over assumptions)
%% Note: out/1 is already defined in core/base.lp
%% -------------------------------------------------------------------------
{ in(X) } :- assumption(X).

%% Range of the extension (for staged: in OR out-but-attacked)
range(X) :- in(X).
range(X) :- assumption(X), defeated(X), not in(X).

%% -------------------------------------------------------------------------
%% Witness extension in2/out2 (another CONFLICT-FREE extension)
%% -------------------------------------------------------------------------
{ in2(X) } :- assumption(X).
out2(X) :- assumption(X), not in2(X).

%% Conflict-free (witness) - use defeated/1 from core/base.lp
:- in2(X), defeated(X).

%% Range (witness) - in OR out-but-defeated
range2(X) :- in2(X).
range2(X) :- assumption(X), defeated(X), not in2(X).

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

%% Staged condition: forbid existence of a better witness
:- better_witness.

#project in/1.
#show in/1.
