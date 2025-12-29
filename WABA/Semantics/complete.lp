%% Complete Semantics
%% An extension is complete if it is admissible and contains all assumptions it defends.
%%
%% Admissible: Conflict-free + self-defending
%% Complete: Admissible + for every assumption X that is defended, X must be in

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
