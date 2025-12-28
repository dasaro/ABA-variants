%% Upper Bound Constraint - MAX Monoid
%% ====================================
%%
%% Enforces: max of discarded attack weights ≤ β
%%
%% Use with: monoid/baseline/max.lp, monoid/max_minimization.lp, monoid/max_maximization.lp
%%
%% Semantics: The highest-cost discarded attack cannot exceed budget (worst-case ceiling)
%%
%% Default: β = #sup (permissive - no limit)
%%   Override with: -c beta=N

#const beta = #sup.
budget(beta).

%% Reject if maximum cost exceeds budget
:- C = #max{ W : discarded_attack(_,_,W) }, C > B, budget(B), B != #sup, C != #inf.

%% Reject if any discarded attack has weight #sup with finite budget
:- discarded_attack(_,_,#sup), budget(B), B != #sup.
