%% Default weight policy selection for unweighted assumptions.
%%
%% Semiring modules provide semiring_default_weight(policy, value).
%% Callers may optionally load one explicit policy module from defaults/.
%% If none is loaded, legacy behavior is preserved.

configured_default_policy :- explicit_default_policy(_).

:- explicit_default_policy(P1), explicit_default_policy(P2), P1 != P2.

active_default_policy(P) :- explicit_default_policy(P).
active_default_policy(legacy) :- not configured_default_policy.

default_assumption_weight(W) :-
    active_default_policy(P),
    semiring_default_weight(P, W).

:- active_default_policy(P), not semiring_default_weight(P, _).
