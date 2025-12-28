%% Lower Bound Constraint - MIN Monoid
%% ====================================
%%
%% Enforces: min of discarded attack weights ≥ β (QUALITY THRESHOLD)
%%
%% Use with: monoid/baseline/min.lp, monoid/min_minimization.lp, monoid/min_maximization.lp
%%
%% Semantics: Lowest-cost discarded attack must meet quality threshold
%%            (standard use case for MIN monoid - ensures quality floor)
%%
%% Default: β = #inf (permissive - no minimum)
%%   Override with: -c beta=N

#const beta = #inf.
budget(beta).

%% Reject if minimum cost below threshold
:- C = #min{ W : discarded_attack(_,_,W) }, C < B, budget(B), B != #inf, C != #inf.

%% Reject if any discarded attack has weight #sup
:- discarded_attack(_,_,#sup).
