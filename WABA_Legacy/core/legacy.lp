budget(beta).

rule(R) :- head(R,_).

%% Each assumption is either in or out
in(X) :- assumption(X), not out(X).
out(X) :- assumption(X), not in(X).

supported(X) :- assumption(X), in(X).
supported(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).

supported_with_weight(X,#sup) :- assumption(X), in(X).
supported_with_weight(X,W) :- supported(X), weight(X,W).
supported_with_weight(X,W) :- supported(X), head(R,X), W = #min{ V, B : body(R,B), supported_with_weight(B,V) }.

attacks_with_weight(X,Y,W) :- supported(X), supported_with_weight(X,W), assumption(Y), contrary(Y,X).

{ discarded_attack(X,Y,W) : attacks_with_weight(X,Y,W) }.

attacks_successfully_with_weight(X,Y,W) :- attacks_with_weight(X,Y,W), not discarded_attack(X,Y,W).
defeated(X) :- attacks_successfully_with_weight(_,X,_).

extension_cost(C) :- C = #max{ W, X, Y : discarded_attack(X,Y,W) }.

:- extension_cost(C), C > B, budget(B).