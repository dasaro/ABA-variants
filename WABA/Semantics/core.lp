budget(beta).

weight(X,0) :- assumption(X).

%% Each assumption is either in or out
in(X) :- assumption(X), not out(X).
out(X) :- assumption(X), not in(X).

%% Everything derivable from assumptions that are in is supported
supported(X) :- in(X).
supported(X) :- head(R,X), rule_supported(R).
rule_supported(R) :- head(R,_), supported(X) : body(R,X).

weight_of_atom(X,W) :- weight(X,W), supported(X).

body_weight(R,S) :-
    rule_supported(R),
    S = #sum { W,B : body(R,B), weight_of_atom(B,W) }.

weight_of_atom(X,M) :-
    supported(X),
    M = #min { S,R : head(R,X), body_weight(R,S) }.

attacks(X,Y,W) :-
    supported(X), contrary(Y,X), weight_of_atom(X,W).

{ discarded_attack(X,Y) : supported(X), attacks(X,Y,_) }.

extension_cost(C) :-
    C = #sum{ W, X, Y : discarded_attack(X,Y), attacks(X,Y,W) }.

:- extension_cost(C), C > B, budget(B).
