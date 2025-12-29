%% Upper Bound Constraint - COUNT Monoid
%% ======================================
%%
%% Enforces: count of discarded attacks ≤ β (STRICT)
%%
%% Use with: monoid/count_minimization.lp, monoid/count_maximization.lp
%%
%% Semantics: Number of discarded attacks cannot exceed budget (weight-agnostic)
%%
%% IMPORTANT: Uses >= (not >) to strictly enforce beta=0 as "no discarding"
%% - With beta=0: NO attacks can be discarded (not even a single one)
%% - With beta=N: Maximum N attacks can be discarded
%%
%% Beta must be defined either:
%%   - In framework file: #const beta = N.
%%   - Via command line: -c beta=N
%%
%% Budget must be defined as:
%%   budget(beta).
%% in your framework file.

%% Reject if count exceeds or equals budget
%% Using >= ensures beta=0 prevents ALL discarding
:- #count{ X,Y : discarded_attack(X,Y,_) } >= B, budget(B), B != #sup.

%% Reject if any discarded attack has weight #sup with finite budget
:- discarded_attack(_,_,#sup), budget(B), B != #sup.
