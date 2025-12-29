%% Lower Bound Constraint - MAX Monoid
%% ====================================
%%
%% Enforces: max of discarded attack weights ≥ β (STRICT)
%%
%% Use with: monoid/max_minimization.lp, monoid/max_maximization.lp
%%
%% Semantics: Highest-cost discarded attack must meet minimum threshold (unusual)
%%
%% IMPORTANT: Uses C <= B (not C < B) for strict boundary enforcement
%% - With beta=N: Requires max(discarded weights) > N (strictly greater)
%% - With beta=0: Forbids zero-weight discards (requires positive weights)
%%
%% Beta must be defined either:
%%   - In framework file: #const beta = N.
%%   - Via command line: -c beta=N
%%
%% Budget must be defined as:
%%   budget(beta).
%% in your framework file.

%% Reject if maximum cost at or below threshold
%% Using <= ensures strict boundary (beta=N requires cost > N)
:- C = #max{ W : discarded_attack(_,_,W) }, C <= B, budget(B), B != #inf, C != #inf.

%% Reject if any discarded attack has weight #sup
:- discarded_attack(_,_,#sup).
