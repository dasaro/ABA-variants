%% Generic upper-bound budget constraint.

active_budget_mode(ub).
active_constraint(ub).

:- not active_monoid(sum), not active_monoid(max), not active_monoid(min), not active_monoid(count).
:- 2 { active_monoid(sum); active_monoid(max); active_monoid(min); active_monoid(count) }.

budget_value(C) :- active_monoid(sum), C = #sum{ W,X,Y : discarded_attack(X,Y,W) }.
budget_value(C) :- active_monoid(max), C = #max{ W : discarded_attack(_,_,W) }.
budget_value(C) :- active_monoid(min), C = #min{ W : discarded_attack(_,_,W) }.
budget_value(C) :- active_monoid(count), C = #count{ X,Y : discarded_attack(X,Y,_) }.

%% An empty discard set spends nothing, so it trivially respects any upper bound.
%% Without this guard the min monoid breaks: #min{} over no discards = #sup, which
%% would spuriously exceed every finite beta and reject the (cost-free) no-discard
%% extension. The max/sum/count empty aggregates (#inf/0/0) already pass an upper
%% bound, so guarding only changes the otherwise-broken min+ub case.
some_discard :- discarded_attack(_,_,_).
:- budget_value(C), C > B, budget(B), some_discard.
:- discarded_attack(_,_,#sup).
