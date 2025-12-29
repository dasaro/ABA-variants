%% Upper Bound Constraint - MIN Monoid
%% ====================================
%%
%% Enforces: min of discarded attack weights ≤ β (STRICT)
%%
%% Use with: monoid/min_minimization.lp, monoid/min_maximization.lp
%%
%% Semantics: The lowest-cost discarded attack cannot exceed budget (unusual use case)
%%
%% NOTE: Upper bounds are uncommon with MIN monoid. Consider using lb_min.lp instead.
%%
%% IMPORTANT: Uses >= (not >) to strictly enforce beta=0 as "no discarding"
%% - With beta=0: NO attacks can be discarded (including zero-weight attacks)
%%
%% Beta must be defined either:
%%   - In framework file: #const beta = N.
%%   - Via command line: -c beta=N
%%
%% Budget must be defined as:
%%   budget(beta).
%% in your framework file.

%% Reject if minimum cost exceeds or equals budget
%% Using >= ensures beta=0 prevents ALL discarding
:- C = #min{ W : discarded_attack(_,_,W) }, C >= B, budget(B), B != #sup, C != #inf.

%% Reject if any discarded attack has weight #sup with finite budget
:- discarded_attack(_,_,#sup), budget(B), B != #sup.
