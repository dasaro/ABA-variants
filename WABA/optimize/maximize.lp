%% Generic maximization objective over the active monoid family.

active_optimization(maximize).

:- active_optimization(minimize).
:- not active_monoid(sum), not active_monoid(max), not active_monoid(min).
:- 2 { active_monoid(sum); active_monoid(max); active_monoid(min) }.

%% Sum: maximize the discarded multiset directly (fast path).
#maximize { W,X,Y : active_monoid(sum), discarded_attack(X,Y,W) }.

%% Max/Min: maximize budget_value/1 (the active monoid aggregate from monoid/<m>.lp).
:~ active_monoid(max), budget_value(M), M = #inf. [1@2]
:~ active_monoid(max), budget_value(M), M != #sup. [-1@1]
:~ active_monoid(max), budget_value(M), M != #sup, M != #inf. [-M@0]

:~ active_monoid(min), budget_value(M), M = #inf. [1@2]
:~ active_monoid(min), budget_value(M), M != #inf. [-1@1]
:~ active_monoid(min), budget_value(M), M != #sup, M != #inf. [-M@0]
