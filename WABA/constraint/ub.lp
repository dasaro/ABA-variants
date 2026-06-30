%% Generic upper-bound budget constraint.

active_budget_mode(ub).
active_constraint(ub).

:- not active_monoid(sum), not active_monoid(max), not active_monoid(min).
:- 2 { active_monoid(sum); active_monoid(max); active_monoid(min) }.

%% budget_value/1 is the active monoid's aggregate, defined once in monoid/<m>.lp.

%% An empty discard set spends nothing, so it trivially respects any upper bound.
%% Without this guard the min monoid breaks: #min{} over no discards = #sup, which
%% would spuriously exceed every finite beta and reject the (cost-free) no-discard
%% extension. The max/sum empty aggregates (#inf/0) already pass an upper
%% bound, so guarding only changes the otherwise-broken min+ub case.
some_discard :- discarded_attack(_,_,_).
:- budget_value(C), C > B, budget(B), some_discard.
:- discarded_attack(_,_,#sup).
