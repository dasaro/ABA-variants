%% Staged Semantics
%% An extension is staged if it is conflict-free and maximal w.r.t. the range
%% (range = set of assumptions that are either in the extension or defeated).
%%
%% Usage: clingo -n 0 --heuristic=Domain --enum=domRec <files> semantics/staged.lp
%%
%% Conflict-free + maximal range

%% Conflict-freeness
:- in(X), defeated(X).

%% Range: assumptions that are in or defeated
in_range(X) :- assumption(X), in(X).
in_range(X) :- assumption(X), defeated(X).

%% Defended assumption (needed for maximality check)
defended(X) :- assumption(X), not undefended_attack(X).

undefended_attack(X) :- assumption(X),
                        attacks_successfully_with_weight(Y,X,_),
                        not defeated(Y).

%% Maximality: An assumption can extend range if it's out, defended, and not in range
%% If such assumption exists, current extension is not maximal
range_extendable(X) :- assumption(X), out(X), defended(X), not in_range(X).

%% Staged: no range-extendable assumptions (maximality constraint)
:- range_extendable(X).
