%% Lower Bound Constraint - COUNT Monoid
%% ======================================
%%
%% Enforces: count of discarded attacks ≥ β (STRICT)
%%
%% Use with: monoid/count_minimization.lp, monoid/count_maximization.lp
%%
%% Semantics: Minimum number of discarded attacks required (unusual use case)
%%
%% IMPORTANT: Uses C <= B (not C < B) for strict boundary enforcement
%% - With beta=N: Requires count(discarded attacks) > N (strictly greater)
%% - With beta=0: Forbids zero discards (requires at least one attack discarded)
%%
%% Beta must be defined either:
%%   - In framework file: #const beta = N.
%%   - Via command line: -c beta=N
%%
%% Budget must be defined as:
%%   budget(beta).
%% in your framework file.

%% Reject if count at or below threshold
%% Using <= ensures strict boundary (beta=N requires count > N)
:- C = #count{ X,Y : discarded_attack(X,Y,_) }, C <= B, budget(B).

%% Reject if any discarded attack has weight #sup
:- discarded_attack(_,_,#sup).
