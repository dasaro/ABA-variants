%% Tropical / min-plus semiring (additive family).
%% Semiring: (ℤ ∪ {+∞}, ⊕=min, ⊗=+, 0̄=#sup, 1̄=0) — cost polarity.
%% Conjunction = accumulate cost (sum); disjunction = cheapest proof (min).
%% Weights are costs, lower is better (shortest path).

active_semiring(tropical).

oplus(min).
oplus_identity(#sup).
otimes_identity(0).

semiring_default_weight(aba,#sup).
semiring_default_weight(neutral,0).

#include "../defaults/base.lp".
#include "_additive.lp".
