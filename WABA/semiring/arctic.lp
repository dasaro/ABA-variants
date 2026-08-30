%% Arctic / max-plus semiring (additive family; negation-dual of tropical).
%% Semiring: (ℤ ∪ {-∞}, ⊕=max, ⊗=+, 0̄=#inf, 1̄=0) — strength polarity.
%% Conjunction = sum weighted premise support; disjunction = greatest-total proof (max).
%% Weights are rewards/benefits on atoms, higher is better.


oplus(max).
oplus_identity(#inf).
otimes_identity(0).

semiring_default_weight(aba,#sup).
semiring_default_weight(neutral,0).

#include "../defaults/base.lp".
#include "_additive.lp".
