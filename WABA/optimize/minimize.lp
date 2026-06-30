%% Generic minimization objective over the active monoid family.

active_optimization(minimize).

:- active_optimization(maximize).
:- not active_monoid(sum), not active_monoid(max), not active_monoid(min).
:- 2 { active_monoid(sum); active_monoid(max); active_monoid(min) }.

%% Sum: minimize the discarded multiset directly (fast path; no single aggregate term).
#minimize { W,X,Y : active_monoid(sum), discarded_attack(X,Y,W) }.

%% Max/Min: minimize budget_value/1 (the active monoid aggregate from monoid/<m>.lp).
%% #sup/#inf are ordered above/below finite costs via separate priority levels.
:~ active_monoid(max), budget_value(M), M = #sup. [1@2]
:~ active_monoid(max), budget_value(M), M = #inf. [0@1]
:~ active_monoid(max), budget_value(M), M != #sup, M != #inf. [M@0]

:~ active_monoid(min), budget_value(M), M = #inf. [1@2]
:~ active_monoid(min), budget_value(M), M = #sup. [0@1]
:~ active_monoid(min), budget_value(M), M != #sup, M != #inf. [M@0]
