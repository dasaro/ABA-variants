%% Lower Bound Constraint - MIN Monoid
%% ====================================
%%
%% Enforces: min of discarded attack weights ≥ β (STRICT QUALITY THRESHOLD)
%%
%% Use with: monoid/min_minimization.lp, monoid/min_maximization.lp
%%
%% Semantics: Lowest-cost discarded attack must meet quality threshold
%%            (standard use case for MIN monoid - ensures quality floor)
%%
%% IMPORTANT: Uses C <= B (not C < B) for strict boundary enforcement
%% - With beta=N: Requires min(discarded weights) > N (strictly greater)
%% - With beta=0: Forbids zero-weight discards (requires positive weights only)
%%
%% Beta must be defined either:
%%   - In framework file: #const beta = N.
%%   - Via command line: -c beta=N
%%
%% Budget must be defined as:
%%   budget(beta).
%% in your framework file.

%% Reject if minimum cost at or below threshold
%% Using <= ensures strict boundary (beta=N requires cost > N)
:- C = #min{ W : discarded_attack(_,_,W) }, C <= B, budget(B), C != #inf.

%% Reject if any discarded attack has weight #sup
:- discarded_attack(_,_,#sup).
