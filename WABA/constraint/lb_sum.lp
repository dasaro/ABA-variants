%% Lower Bound Constraint - SUM Monoid
%% ====================================
%%
%% Enforces: sum of discarded attack weights ≥ β (STRICT)
%%
%% Use with: monoid/sum_minimization.lp, monoid/sum_maximization.lp
%%
%% Semantics: Total cost must meet minimum threshold (unusual use case)
%%
%% IMPORTANT: Uses C <= B (not C < B) for strict boundary enforcement
%% - With beta=N: Requires sum(discarded weights) > N (strictly greater)
%% - With beta=0: Forbids zero total cost (requires at least one positive-weight discard)
%%
%% Beta must be defined either:
%%   - In framework file: #const beta = N.
%%   - Via command line: -c beta=N
%%
%% Budget must be defined as:
%%   budget(beta).
%% in your framework file.

%% Reject if total cost at or below threshold
%% Using <= ensures strict boundary (beta=N requires cost > N)
:- C = #sum{ W,X,Y : discarded_attack(X,Y,W) }, C <= B, budget(B), B != #inf.

%% Reject if any discarded attack has weight #sup
:- discarded_attack(_,_,#sup).
