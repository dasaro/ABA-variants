%% Semi-Stable Semantics
%% An extension is semi-stable if it is a maximal (w.r.t. set of defeated arguments)
%% complete extension.
%%
%% Usage: clingo -n 0 --heuristic=Domain --enum=domRec <files> semantics/semi-stable.lp
%%
%% Complete: Admissible + contains all defended assumptions
%% Semi-stable: Maximal w.r.t. the set of defeated arguments

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

%% Completeness: All defended assumptions must be in
:- defended(X), out(X).

%% Heuristic to maximize defeated arguments (include more assumptions to attack more)
%% Prefer including assumptions that lead to more attacks
#heuristic in(X) : assumption(X), defended(X). [1,true]
