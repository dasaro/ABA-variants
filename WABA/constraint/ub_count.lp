%% Upper Bound Constraint - COUNT Monoid
%% ======================================
%%
%% Enforces: count of discarded attacks ≤ β
%%
%% Use with: monoid/baseline/count.lp, monoid/count_minimization.lp, monoid/count_maximization.lp
%%
%% Semantics: Number of discarded attacks cannot exceed budget (weight-agnostic)
%%
%% Default: β = #sup (permissive - no limit)
%%   Override with: -c beta=N

#const beta = #sup.
budget(beta).

%% Reject if count exceeds budget
:- #count{ X,Y : discarded_attack(X,Y,_) } > B, budget(B), B != #sup.

%% Reject if any discarded attack has weight #sup with finite budget
:- discarded_attack(_,_,#sup), budget(B), B != #sup.
