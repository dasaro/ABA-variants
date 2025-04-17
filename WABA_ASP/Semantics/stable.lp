%% Assumption is either in or out
in(X) :- assumption(X), not out(X).
out(X) :- assumption(X), not in(X).

%% Everything derivable from assumptions that are in
supported(X) :- assumption(X), in(X).
supported(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).
weight_of_triggered_rule(R,W) :- triggered_by_in(R), head(R,_), W = #min{ V, X : supported(X), body(R,X), weight(X,V) }.

attacks(X,Y,W) :- supported(X), contrary(Y,X), weight_of_triggered_rule(R,W), head(R,X).
{ discarded_attack(X,Y) : supported(X), attacks(X,Y,_) }.
total_weight(Wtotal) :- Wtotal = #sum{ W, X, Y : discarded_attack(X,Y), attacks(X,Y,W) }.
:- total_weight(Wtotal), Wtotal > B, budget(B).

%% conflict freeness
:- in(X), attacks(Y,X,_), not discarded_attack(Y,X), supported(Y).

%% assumptions attacked by the in arguments
defeated(X) :- supported(Y), attacks(Y,X,_), not discarded_attack(Y,X).

%% stable
:- not defeated(X), out(X).

#show in/1.
#show total_weight/1.
#show allowed_attack/2.
#show supported/1.
