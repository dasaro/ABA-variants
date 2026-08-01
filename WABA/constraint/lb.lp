%% Generic lower-bound budget constraint.


%% budget_value/1 is the active monoid's aggregate, defined once in monoid/<m>.lp.

%% beta MUST be an integer whenever this module is loaded.
%%
%% Without this, omitting `-c beta` leaves `beta` an uninterpreted constant. clingo orders
%% every integer strictly BELOW an uninterpreted constant, so the comparison below still
%% GROUNDS and still SUCCEEDS -- it simply never fires. The failure is therefore silent, and
%% it runs in OPPOSITE directions for the two bounds: `C > beta` becomes unsatisfiable, so
%% ub is silently unbounded and admits every discard; `C < beta` becomes universally true,
%% so lb silently collapses onto no_discard. Measured on a two-assumption cycle: ub without
%% `-c beta` returns 3 extensions where `-c beta=0` returns 2.
%%
%% The test is arithmetic, not comparison, precisely because comparison is total over
%% clingo's term order while `+` is undefined on a symbolic constant. It lives here rather
%% than in core/base.lp so that runs loading no budget module never ground it.
beta_is_integer :- beta = B, B = B + 0.
:- not beta_is_integer.


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

