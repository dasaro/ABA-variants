%% Arctic / max-plus semiring (additive family; negation-dual of tropical).
%% Semiring: (ℤ ∪ {-∞}, ⊕=max, ⊗=+, 0̄=#inf, 1̄=0) — strength polarity.
%% Conjunction = accumulate reward (sum); disjunction = strongest chain (max).
%% Weights are rewards/benefits, higher is better (longest path).

active_semiring(arctic).

oplus(max).
oplus_identity(#inf).
otimes_identity(0).
affordability_polarity(strength).

semiring_default_weight(legacy,0).
semiring_default_weight(aba,#sup).
semiring_default_weight(neutral,0).

#include "../defaults/base.lp".
#include "_additive.lp".
