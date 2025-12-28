%% Lower Bound Constraint - COUNT Monoid
%% ======================================
%%
%% Enforces: count of discarded attacks ≥ β
%%
%% Use with: monoid/baseline/count.lp, monoid/count_minimization.lp, monoid/count_maximization.lp
%%
%% Semantics: Minimum number of discarded attacks required (unusual use case)
%%
%% Default: β = #inf (permissive - no minimum)
%%   Override with: -c beta=N

#const beta = #inf.
budget(beta).

%% Reject if count below threshold
:- C = #count{ X,Y : discarded_attack(X,Y,_) }, C < B, budget(B), B != #inf.

%% Reject if any discarded attack has weight #sup
:- discarded_attack(_,_,#sup).
