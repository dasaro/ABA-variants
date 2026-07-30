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
:- budget_value(C), C > B, effective_budget(B), some_discard.

%% #sup weights are un-discardable at any budget (a maximal-cost / un-droppable attack).
:- discarded_attack(_,_,#sup).

%% Exact classical-ABA recovery is constraint/no_discard.lp (forbids ALL discards, for
%% ANY weight) — NOT ub with beta=0. A budget of 0 here is a genuine budget=0: the cost
%% semirings' ⊗-identity (#inf, the "negligible-cost" weight of an unweighted
%% attack or a fact-derived contrary) is free to discard at any budget by design — a
%% zero-cost attack costs nothing to drop. For plain ABA use no_discard, or the `aba`
%% default policy (unweighted attacks are then #sup, hence un-discardable above).

%% An unbound `beta` is not "budget disabled". clingo orders every integer strictly BELOW an
%% uninterpreted constant, so with a symbolic beta the comparison above can never fire (ub)
%% or always fires (lb) -- silent, and in opposite directions. Reject instead. The `B+0` test
%% is arithmetic, undefined on a symbolic constant, so the rule simply does not fire; the
%% accompanying "operation undefined" info is emitted only in that misconfigured case.
integer_budget(B) :- effective_budget(B), B = B + 0.
:- effective_budget(B), not integer_budget(B).
