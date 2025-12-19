%% WABA Base Logic (Semiring/Monoid-Independent)
%% This file contains the core argumentation logic that is independent
%% of the choice of semiring (weight propagation) and monoid (cost aggregation).

budget(beta).

%% Rule meta-predicate
rule(R) :- head(R,_).

%% Assumption choice: each assumption is either in or out
in(X) :- assumption(X), not out(X).
out(X) :- assumption(X), not in(X).

%% Support computation (weight-independent)
%% An atom is supported if:
%% 1. It's an assumption that is in, OR
%% 2. There exists a rule with this atom as head and all body elements are supported
supported(X) :- assumption(X), in(X).
supported(X) :- head(R,X), triggered_by_in(R).

%% A rule is triggered when all its body elements are supported
triggered_by_in(R) :- head(R,_), supported(X) : body(R,X).

%% Attack computation
%% An attack exists when a supported atom X attacks an assumption Y
%% (where Y's contrary is X), with the weight of X
attacks_with_weight(X,Y,W) :- supported(X), supported_with_weight(X,W),
                               assumption(Y), contrary(Y,X).

%% Attack discretion choice
%% We can choose to discard any attack (at a cost)
{ discarded_attack(X,Y,W) : attacks_with_weight(X,Y,W) }.

%% Successful attacks
%% An attack succeeds if it's not discarded
attacks_successfully_with_weight(X,Y,W) :- attacks_with_weight(X,Y,W),
                                             not discarded_attack(X,Y,W).

%% Defeat
%% An assumption is defeated if there's a successful attack against it
defeated(X) :- attacks_successfully_with_weight(_,X,_).

%% Budget constraint
:- extension_cost(C), C > B, budget(B).
