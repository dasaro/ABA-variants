%% Upper Bound Constraint - MAX Monoid
%% ====================================
%%
%% Enforces: max of discarded attack weights ≤ β
%%
%% Use with: monoid/baseline/max.lp, monoid/max_minimization.lp, monoid/max_maximization.lp
%%
%% Semantics: The highest-cost discarded attack cannot exceed budget (worst-case ceiling)
%%
%% Beta must be defined either:
%%   - In framework file: #const beta = N.
%%   - Via command line: -c beta=N
%%
%% Budget must be defined as:
%%   budget(beta).
%% in your framework file.
%%
%% DO NOT rely on automatic budget definition - it causes UNSATISFIABLE with beta=0!

%% Reject if maximum cost exceeds budget
:- C = #max{ W : discarded_attack(_,_,W) }, C > B, budget(B), B != #sup, C != #inf.

%% Reject if any discarded attack has weight #sup with finite budget
:- discarded_attack(_,_,#sup), budget(B), B != #sup.
