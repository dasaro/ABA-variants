%% Sum monoid family.
%% Aggregate: sum of discarded attack weights.
%% Identity on the empty set: 0.
%% #sum silently omits #inf tuples, but the lifted sum used here makes #inf absorbing:
%% once any discarded unit has price #inf, the whole aggregate is #inf.

active_monoid(sum).

%% Canonical aggregate over the discarded-attack multiset (single source of truth).
%% Consumed by constraint/ub.lp, constraint/lb.lp and optimize/{minimize,maximize}.lp.
sum_has_infimum :- discarded_attack(_,_,#inf).
budget_value(#inf) :- sum_has_infimum.
budget_value(C) :- not sum_has_infimum,
    C = #sum{ W,X,Y : discarded_attack(X,Y,W) }.
