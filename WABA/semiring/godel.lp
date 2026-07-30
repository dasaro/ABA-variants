%% Gödel / Fuzzy semiring (idempotent family).
%% Semiring: (ℤ ∪ {±∞}, ⊕=max, ⊗=min, 0̄=#inf, 1̄=#sup) — strength polarity.
%% Conjunction = weakest link (min); disjunction = strongest alternative (max).
%% Weights are truth degrees / confidences, higher is better (original WABA).

active_semiring(godel).

oplus(max).
otimes(min).
oplus_identity(#inf).
otimes_identity(#sup).

semiring_default_weight(aba,#sup).
semiring_default_weight(neutral,#sup).

#include "../defaults/base.lp".
#include "_idempotent.lp".
