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

%% delta resolves to ONE value, so say it in two rules rather than routing it through a
%% `configured_default_policy` flag and an `active_default_policy` relation. The "exactly one
%% policy module is loaded" and "that policy is defined for this semiring" checks moved to the
%% boundary with the framework preconditions: bin/waba and the web program-builder each load
%% exactly one defaults/*.lp by construction, so neither is reachable from a supported run.
default_assumption_weight(W) :-
    explicit_default_policy(P), semiring_default_weight(P, W).
default_assumption_weight(W) :-
    not explicit_default_policy(_), semiring_default_weight(neutral, W).
