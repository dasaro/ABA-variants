%% Generic lower-bound budget constraint.


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

