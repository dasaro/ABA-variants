%% Generic minimization objective over the active monoid family.

active_optimization(minimize).

:- active_optimization(maximize).

%% Sum: rank its canonical budget_value/1 rather than the raw tuples.  Raw #minimize
%% would silently omit a #inf tuple and tie an absorbing-#inf aggregate with a finite one.
%% Priority 2 puts #sup above every usable aggregate; priority 1 puts every finite sum
%% above #inf; priority 0 orders the finite sums normally.
:~ active_monoid(sum), budget_value(M), M = #sup. [1@2]
:~ active_monoid(sum), budget_value(M), M != #sup, M != #inf. [1@1]
:~ active_monoid(sum), budget_value(M), M != #sup, M != #inf. [M@0]

%% Max/Min: minimize budget_value/1 (the active monoid aggregate from monoid/<m>.lp).
%% #sup/#inf are ordered above/below finite costs via separate priority levels.
:~ active_monoid(max), budget_value(M), M = #sup. [1@2]
:~ active_monoid(max), budget_value(M), M = #inf. [0@1]
:~ active_monoid(max), budget_value(M), M != #sup, M != #inf. [M@0]

:~ active_monoid(min), budget_value(M), M = #inf. [1@2]
:~ active_monoid(min), budget_value(M), M = #sup. [0@1]
:~ active_monoid(min), budget_value(M), M != #sup, M != #inf. [M@0]
