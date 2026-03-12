%% Generic lower-bound budget constraint.

active_budget_mode(lb).
active_constraint(lb).

:- not active_monoid(sum), not active_monoid(max), not active_monoid(min), not active_monoid(count).
:- 2 { active_monoid(sum); active_monoid(max); active_monoid(min); active_monoid(count) }.

budget_value(C) :- active_monoid(sum), C = #sum{ W,X,Y : discarded_attack(X,Y,W) }.
budget_value(C) :- active_monoid(max), C = #max{ W : discarded_attack(_,_,W) }.
budget_value(C) :- active_monoid(min), C = #min{ W : discarded_attack(_,_,W) }.
budget_value(C) :- active_monoid(count), C = #count{ X,Y : discarded_attack(X,Y,_) }.

:- budget_value(C), C < B, budget(B).
:- discarded_attack(_,_,#sup).
