%% Min monoid family.
%% Aggregate: minimum discarded attack weight.
%% Identity on the empty set: #sup.

active_monoid(min).

%% Canonical aggregate over the discarded-attack multiset (single source of truth).
%% Consumed by constraint/ub.lp, constraint/lb.lp and optimize/{minimize,maximize}.lp.
budget_value(C) :- C = #min{ W : discarded_attack(_,_,W) }.
