%% Generic lower-bound budget constraint.

active_budget_mode(lb).
active_constraint(lb).

:- not active_monoid(sum), not active_monoid(max), not active_monoid(min), not active_monoid(count).
:- 2 { active_monoid(sum); active_monoid(max); active_monoid(min); active_monoid(count) }.

budget_value(C) :- active_monoid(sum), C = #sum{ W,X,Y : discarded_attack(X,Y,W) }.
budget_value(C) :- active_monoid(max), C = #max{ W : discarded_attack(_,_,W) }.
budget_value(C) :- active_monoid(min), C = #min{ W : discarded_attack(_,_,W) }.
budget_value(C) :- active_monoid(count), C = #count{ X,Y : discarded_attack(X,Y,_) }.

%% An empty discard set spends nothing; it does not "meet" a positive lower bound,
%% but it must remain FEASIBLE (the no-discard extension always exists). Without this
%% guard the max monoid breaks: #max{} over no discards = #inf < beta, which would
%% reject the no-discard extension outright. The min empty aggregate (#sup) already
%% passes a lower bound, so guarding only changes the otherwise-broken max+lb case.
some_discard :- discarded_attack(_,_,_).
:- budget_value(C), C < B, budget(B), some_discard.
:- discarded_attack(_,_,#sup).
