%% Upper Bound Constraint - SUM Monoid
%% =====================================
%%
%% Enforces: sum of discarded attack weights ≤ β (STRICT)
%%
%% Use with: monoid/sum_minimization.lp, monoid/sum_maximization.lp
%%
%% Semantics: Total cost of discarded attacks cannot exceed budget
%%
%% IMPORTANT: Uses >= (not >) to strictly enforce beta=0 as "no discarding"
%% - With beta=0: NO attacks can be discarded (including zero-weight attacks)
%% - With beta=N: Only combinations with total cost > N are forbidden
%%
%% Beta must be defined either:
%%   - In framework file: #const beta = N.
%%   - Via command line: -c beta=N
%%
%% Budget must be defined as:
%%   budget(beta).
%% in your framework file.

%% Reject if total cost exceeds or equals budget
%% Using >= ensures beta=0 prevents ALL discarding
:- #sum{ W,X,Y : discarded_attack(X,Y,W) } >= B, budget(B), B != #sup.

%% Reject if any discarded attack has weight #sup with finite budget
:- discarded_attack(_,_,#sup), budget(B), B != #sup.
