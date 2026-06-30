%% Sum monoid family.
%% Aggregate: sum of discarded attack weights.
%% Identity on the empty set: 0.

active_monoid(sum).

%% Canonical aggregate over the discarded-attack multiset (single source of truth).
%% Consumed by constraint/ub.lp, constraint/lb.lp and optimize/{minimize,maximize}.lp.
budget_value(C) :- C = #sum{ W,X,Y : discarded_attack(X,Y,W) }.
