%% Upper Bound Constraint - MAX Monoid
%% ====================================
%%
%% Enforces: max of discarded attack weights ≤ β (STRICT)
%%
%% Use with: monoid/max_minimization.lp, monoid/max_maximization.lp
%%
%% Semantics: The highest-cost discarded attack cannot exceed budget (worst-case ceiling)
%%
%% IMPORTANT: Uses C >= B (not C > B) to strictly enforce beta=0 as "no discarding"
%% - With beta=0: NO attacks can be discarded (including zero-weight attacks)
%% - With beta=N: Only attacks with weight > N are forbidden
%%
%% Beta must be defined either:
%%   - In framework file: #const beta = N.
%%   - Via command line: -c beta=N
%%
%% Budget must be defined as:
%%   budget(beta).
%% in your framework file.

%% Reject if maximum cost exceeds or equals budget
%% Using >= ensures beta=0 prevents ALL discarding (including zero-weight attacks)
%% Works with beta=#sup: only rejects when C=#sup (prevents discarding #sup-weighted attacks)
:- C = #max{ W : discarded_attack(_,_,W) }, C >= B, budget(B), C != #inf.

%% Reject if any discarded attack has weight #sup (regardless of budget)
:- discarded_attack(_,_,#sup).
