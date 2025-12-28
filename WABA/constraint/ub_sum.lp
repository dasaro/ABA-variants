%% Upper Bound Constraint - SUM Monoid
%% =====================================
%%
%% Enforces: sum of discarded attack weights ≤ β
%%
%% Use with: monoid/baseline/sum.lp, monoid/sum_minimization.lp, monoid/sum_maximization.lp
%%
%% Semantics: Total cost of discarded attacks cannot exceed budget
%%
%% Default: β = #sup (permissive - no limit)
%%   Override with: -c beta=N

#const beta = #sup.
budget(beta).

%% Reject if total cost exceeds budget
:- #sum{ W,X,Y : discarded_attack(X,Y,W) } > B, budget(B), B != #sup.

%% Reject if any discarded attack has weight #sup with finite budget
:- discarded_attack(_,_,#sup), budget(B), B != #sup.
