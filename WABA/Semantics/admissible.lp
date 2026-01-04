%% Admissible Semantics for WABA
%%
%% In WABA, admissibility extends conflict-free semantics with a constraint
%% that forbids unnecessary attack discarding:
%%   - Attack discarding is only allowed when the target is IN (i.e., to resolve conflicts)
%%   - Gratuitous discarding of attacks on OUT or UNDEC elements is forbidden
%%
%% This ensures the semantic hierarchy: Stable ⊆ Admissible ⊆ CF
%%   - Stronger than CF (forbids unnecessary discarding)
%%   - Weaker than Stable (allows partial labelings with UNDEC elements)

%% Guess an extension
{ in(X) } :- assumption(X).

%% Conflict-free: no successful attacks between IN elements
:- supported(X), in(Y), attacks_successfully_with_weight(X,Y,_).

%% Labeling
out(X)  :- assumption(X), in(Y), attacks_successfully_with_weight(Y,X,_).
undec(X):- assumption(X), not in(X), not out(X).

%% ADMISSIBILITY: Only discard attacks when necessary (target is IN)
%% Forbids discarding attacks on OUT or UNDEC elements (unnecessary discarding)
:- discarded_attack(X,Y,_), not in(Y).
