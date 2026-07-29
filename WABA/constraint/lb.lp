%% Generic lower-bound budget constraint.

active_budget_mode(lb).
active_constraint(lb).

:- not active_monoid(sum), not active_monoid(max), not active_monoid(min).
:- 2 { active_monoid(sum); active_monoid(max); active_monoid(min) }.

%% budget_value/1 is the active monoid's aggregate, defined once in monoid/<m>.lp.

%% An empty discard set spends nothing; it does not "meet" a positive lower bound,
%% but it must remain FEASIBLE (the no-discard extension always exists). Without this
%% guard the max monoid breaks: #max{} over no discards = #inf < beta, which would
%% reject the no-discard extension outright. The min empty aggregate (#sup) already
%% passes a lower bound, so guarding only changes the otherwise-broken max+lb case.
some_discard :- discarded_attack(_,_,_).
:- budget_value(C), C < B, effective_budget(B), some_discard.

%% #sup weights are un-discardable at any budget (a maximal-cost / un-droppable attack).
:- discarded_attack(_,_,#sup).

%% For plain ABA (no discards at all) use constraint/no_discard.lp, not a budget here.

%% An unbound `beta` is not "budget disabled". clingo orders every integer strictly BELOW an
%% uninterpreted constant, so with a symbolic beta the comparison above can never fire (ub)
%% or always fires (lb) -- silent, and in opposite directions. Reject instead. The `B+0` test
%% is arithmetic, undefined on a symbolic constant, so the rule simply does not fire; the
%% accompanying "operation undefined" info is emitted only in that misconfigured case.
integer_budget(B) :- effective_budget(B), B = B + 0.
:- effective_budget(B), not integer_budget(B).
