%% Lower Bound Constraint - SUM Monoid
%% ====================================
%%
%% Enforces: sum of discarded attack weights ≥ β
%%
%% Use with: monoid/baseline/sum.lp, monoid/sum_minimization.lp, monoid/sum_maximization.lp
%%
%% Semantics: Total cost must meet minimum threshold (unusual use case)
%%
%% Default: β = #inf (permissive - no minimum)
%%   Override with: -c beta=N

#const beta = #inf.
budget(beta).

%% Reject if total cost below threshold
:- C = #sum{ W,X,Y : discarded_attack(X,Y,W) }, C < B, budget(B), B != #inf.

%% Reject if any discarded attack has weight #sup
:- discarded_attack(_,_,#sup).
