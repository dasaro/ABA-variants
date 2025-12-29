%% Grounded Semantics
%% The grounded extension is the unique minimal (w.r.t. set inclusion) complete extension.
%%
%% Usage: clingo -n 1 --heuristic=Domain --enum=domRec <files> semantics/grounded.lp
%%        (Use -n 1 since grounded extension is unique)
%%
%% Complete: Admissible + contains all defended assumptions
%% Grounded: Minimal complete

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

%% Heuristic to minimize the extension (prefer excluding assumptions when possible)
#heuristic in(X) : assumption(X). [1,false]
