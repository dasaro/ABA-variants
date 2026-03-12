%% Generic maximization objective over the active monoid family.

active_optimization(maximize).

:- active_optimization(minimize).
:- not active_monoid(sum), not active_monoid(max), not active_monoid(min), not active_monoid(count).
:- 2 { active_monoid(sum); active_monoid(max); active_monoid(min); active_monoid(count) }.

#maximize { W,X,Y : active_monoid(sum), discarded_attack(X,Y,W) }.
#maximize { 1,X,Y : active_monoid(count), discarded_attack(X,Y,_) }.

:~ active_monoid(max), M = #max { W : discarded_attack(_,_,W) }, M = #inf. [1@2]
:~ active_monoid(max), M = #max { W : discarded_attack(_,_,W) }, M != #sup. [-1@1]
:~ active_monoid(max), M = #max { W : discarded_attack(_,_,W) }, M != #sup, M != #inf. [-M@0]

:~ active_monoid(min), M = #min { W : discarded_attack(_,_,W) }, M = #inf. [1@2]
:~ active_monoid(min), M = #min { W : discarded_attack(_,_,W) }, M != #inf. [-1@1]
:~ active_monoid(min), M = #min { W : discarded_attack(_,_,W) }, M != #sup, M != #inf. [-M@0]
