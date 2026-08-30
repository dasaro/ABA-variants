%% Ordinary ABA conflict-free semantics over the fixed reduced attack relation
%% Att \ D selected by the common beta layer in core/base.lp.
#project in/1.
#project out/1.

1 { in(X); out(X) } 1 :- assumption(X).

%% S attacks Y in the reduced framework iff S derives an attacking conclusion X
%% and the fixed atom-level attack X -> Y was not discarded.
defeated(Y) :- attacks_successfully_with_weight(_,Y,_).

:- in(Y), defeated(Y).
