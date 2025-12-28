%% Upper Bound Constraint - MIN Monoid
%% ====================================
%%
%% Enforces: min of discarded attack weights ≤ β
%%
%% Use with: monoid/baseline/min.lp, monoid/min_minimization.lp, monoid/min_maximization.lp
%%
%% Semantics: The lowest-cost discarded attack cannot exceed budget (unusual use case)
%%
%% NOTE: Upper bounds are uncommon with MIN monoid. Consider using lb_min.lp instead.
%%
%% Default: β = #sup (permissive - no limit)
%%   Override with: -c beta=N

#const beta = #sup.
budget(beta).

%% Reject if minimum cost exceeds budget
:- C = #min{ W : discarded_attack(_,_,W) }, C > B, budget(B), B != #sup, C != #inf.

%% Reject if any discarded attack has weight #sup with finite budget
:- discarded_attack(_,_,#sup), budget(B), B != #sup.
