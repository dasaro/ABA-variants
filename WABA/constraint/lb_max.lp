%% Lower Bound Constraint - MAX Monoid
%% ====================================
%%
%% Enforces: max of discarded attack weights ≥ β
%%
%% Use with: monoid/baseline/max.lp, monoid/max_minimization.lp, monoid/max_maximization.lp
%%
%% Semantics: Highest-cost discarded attack must meet minimum threshold (unusual)
%%
%% Default: β = #inf (permissive - no minimum)
%%   Override with: -c beta=N

#const beta = #inf.
budget(beta).

%% Reject if maximum cost below threshold
:- C = #max{ W : discarded_attack(_,_,W) }, C < B, budget(B), B != #inf, C != #inf.

%% Reject if any discarded attack has weight #sup
:- discarded_attack(_,_,#sup).
