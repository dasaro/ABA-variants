%% Default weight policy selection for unweighted assumptions.
%%
%% Semiring modules provide semiring_default_weight(policy, value).
%% Callers may optionally load one explicit policy module from defaults/.
%% If none is loaded the `neutral` policy applies: delta = the semiring's ⊗-identity, so an
%% unweighted assumption is TRANSPARENT in a conjunction.
%%
%% This used to default to a third policy, `legacy`, retired on 2026-07-30. A policy
%% contributes exactly one constant, and legacy's coincided with `neutral` for godel, arctic,
%% lukasiewicz and bottleneck_cost, and with `aba` for tropical -- so it was a third name for
%% behaviour already reachable. Its one distinctive effect was on TROPICAL, where delta was
%% #sup (the ⊗-annihilator) rather than 0; `--default-policy aba` still provides exactly that.

configured_default_policy :- explicit_default_policy(_).

:- explicit_default_policy(P1), explicit_default_policy(P2), P1 != P2.

active_default_policy(P) :- explicit_default_policy(P).
active_default_policy(neutral) :- not configured_default_policy.

default_assumption_weight(W) :-
    active_default_policy(P),
    semiring_default_weight(P, W).

:- active_default_policy(P), not semiring_default_weight(P, _).
