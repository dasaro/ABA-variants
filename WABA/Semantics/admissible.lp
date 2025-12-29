%% Admissible Semantics
%% An extension is admissible if it is conflict-free and defends all its members.
%%
%% Usage: clingo -n 0 <files> semantics/admissible.lp
%%
%% Conflict-free: No assumption in the extension is defeated
%% Self-defending: Every assumption in the extension must be defended
%%                (all its attackers must be defeated)

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
