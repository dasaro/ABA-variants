%% Preferred Semantics
%% An extension is preferred if it is a maximal (w.r.t. set inclusion) admissible set.
%%
%% Usage: clingo -n 0 --heuristic=Domain --enum=domRec <files> semantics/preferred.lp
%%
%% Admissible: Conflict-free + self-defending
%% Preferred: Maximal admissible

%% Conflict-freeness
:- in(X), defeated(X).

%% Defended assumption: X is defended if all its attackers are defeated
defended(X) :- assumption(X),
               not undefended_attack(X).

undefended_attack(X) :- assumption(X),
                        attacks_successfully_with_weight(Y,X,_),
                        not defeated(Y).

%% Admissibility: All in assumptions must be defended
:- in(X), not defended(X).

%% Maximality (saturation-based approach):
%% An admissible extension is preferred iff no out assumption can be added
%% An assumption X can be added if it's out AND defended by current extension
%% If such X exists, the extension is not maximal -> reject it

extendable(X) :- assumption(X), out(X), defended(X).

%% Preferred: no extendable assumptions (maximality constraint)
:- extendable(X).
