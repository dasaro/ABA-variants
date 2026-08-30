%% Generic maximization objective over the active monoid family.

active_optimization(maximize).

:- active_optimization(minimize).

%% Sum: rank its canonical budget_value/1 rather than the raw tuples.  Raw #maximize
%% would silently omit a #inf tuple.  Priority 2 makes that absorbing value smaller
%% than every finite sum; priority 1 keeps finite sums below #sup; priority 0 orders
%% finite sums in the requested descending direction.
:~ active_monoid(sum), budget_value(M), M = #inf. [1@2]
:~ active_monoid(sum), budget_value(M), M != #sup, M != #inf. [1@1]
:~ active_monoid(sum), budget_value(M), M != #sup, M != #inf. [-M@0]

%% Max/Min: maximize budget_value/1 (the active monoid aggregate from monoid/<m>.lp).
:~ active_monoid(max), budget_value(M), M = #inf. [1@2]
:~ active_monoid(max), budget_value(M), M != #sup. [-1@1]
:~ active_monoid(max), budget_value(M), M != #sup, M != #inf. [-M@0]

:~ active_monoid(min), budget_value(M), M = #inf. [1@2]
:~ active_monoid(min), budget_value(M), M != #inf. [-1@1]
:~ active_monoid(min), budget_value(M), M != #sup, M != #inf. [-M@0]
