%% Max monoid family.
%% Aggregate: maximum discarded attack weight.
%% Identity on the empty set: #inf.

active_monoid(max).

%% Canonical aggregate over the discarded-attack multiset (single source of truth).
%% Consumed by constraint/ub.lp, constraint/lb.lp and optimize/{minimize,maximize}.lp.
budget_value(C) :- C = #max{ W : discarded_attack(_,_,W) }.
