%% Ordinary ABA stable semantics over the fixed reduced attack relation Att \ D
%% selected by the common beta layer in core/base.lp.
#project in/1.
#project out/1.

1 { in(X); out(X) } 1 :- assumption(X).

%% Conflict-free on successful attacks
:- in(Y), attacks_successfully_with_weight(_,Y,_).

%% Defeated-by-S (counterattacked)
defeated(Y) :- attacks_successfully_with_weight(_,Y,_).

%% stable
:- out(X), not defeated(X).
