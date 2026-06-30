%% Bottleneck-cost semiring (idempotent family; order-dual of godel).
%% Semiring: (ℤ ∪ {±∞}, ⊕=min, ⊗=max, 0̄=#sup, 1̄=#inf) — cost polarity.
%% Conjunction = worst step (max); disjunction = cheapest alternative (min).
%% An argument costs as much as its single worst step (worst-case path).

active_semiring(bottleneck_cost).

oplus(min).
otimes(max).
oplus_identity(#sup).
otimes_identity(#inf).
affordability_polarity(cost).

semiring_default_weight(legacy,#inf).
semiring_default_weight(aba,#sup).
semiring_default_weight(neutral,#inf).

#include "../defaults/base.lp".
#include "_idempotent.lp".
