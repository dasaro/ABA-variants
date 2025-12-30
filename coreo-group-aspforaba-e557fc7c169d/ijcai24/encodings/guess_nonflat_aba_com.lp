%% Assumption is either in or out
in(X) :- assumption(X), not out(X).
out(X) :- assumption(X), not in(X).

%% Everything derivable from assumptions that are in
derived(X) :- assumption(X), in(X).
derived(X) :- head(R,X), triggered_by_in(R).
triggered_by_in(R) :- head(R,_), derived(X) : body(R,X).

%% Conflict freeness
:- in(X), contrary(X,Y), derived(Y).

%% In is closed
:- assumption(X), derived(X), not in(X).

%% assumptions attacked by the in arguments
defeated(X) :- derived(Y), contrary(X,Y).

%% Everything derivable from assumptionpts that are not defeated by in
derived_from_undefeated(X) :- assumption(X), not defeated(X).
derived_from_undefeated(X) :- head(R,X), triggered_by_undefeated(R).
triggered_by_undefeated(R) :- head(R,_), derived_from_undefeated(X) : body(R,X).

%% X is attacked by assumptionpts that are not attacked by in
attacked_by_undefeated(X) :- contrary(X,Y), derived_from_undefeated(Y).

%% A bit stronger, if undefeated is closed and attacks in, then in is not an extension
undef_not_closed :- assumption(X), derived_from_undefeated(X), not defeated(X).
:- in(X), attacked_by_undefeated(X), not undef_not_closed.

%% Completeness - I think this is a necessary condition FOR COMPLETE SEMANTICS. In verification step, need to also check that each out assumption attacked _by a closed set_
:- out(X), not attacked_by_undefeated(X).

not_att_by_undef(X) :- not attacked_by_undefeated(X), assumption(X).
#show not_att_by_undef/1.

#show in/1.
#show defeated/1.
#show derived/1.
