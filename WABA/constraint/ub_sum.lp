%% Upper Bound Constraint - SUM Monoid
%% =====================================
%%
%% Enforces: sum of discarded attack weights ≤ β (STRICT)
%%
%% Use with: monoid/sum_minimization.lp, monoid/sum_maximization.lp
%%
%% Semantics: Total cost of discarded attacks cannot exceed budget
%%
%% Beta must be defined either:
%%   - In framework file: #const beta = N.
%%   - Via command line: -c beta=N
%%
%% Budget must be defined as:
%%   budget(beta).
%% in your framework file.

%% Reject if total cost EXCEEDS budget (sum > beta)
%% At beta=0: allows extensions with NO discarded attacks (sum=0)
:- #sum{ W,X,Y : discarded_attack(X,Y,W) } > B, budget(B).

%% Reject if any discarded attack has weight #sup with finite budget
:- discarded_attack(_,_,#sup).
