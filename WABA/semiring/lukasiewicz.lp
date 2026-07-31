%% Łukasiewicz / bounded-sum semiring (outside the godel/tropical 2×2).
%% Semiring: ({0..k}, ⊕=max, ⊗=max(0, a+b-k), 0̄=0, 1̄=k) — strength polarity.
%% n-ary ⊗: max(0, (Σ wi) - (n-1)*k). Unlike Gödel's weakest-link, a chain of weak
%% premises ERODES certainty toward 0. The only ⊗ that is not min, max or plain +,
%% so it shares _phase.lp's propagation skeleton but supplies its own rule_deriv/4.
%% Weights live on the integer grid {0..k} (#const k, default 1000); override -c k=N.

#const k = 1000.


oplus(max).
oplus_identity(0).
otimes_identity(k).

%% aba default is #sup (un-discardable): an unweighted assumption then behaves as a
%% plain ABA assumption whose attack survives any finite budget, so β=0 / no_discard
%% recovers classical ABA at every k. (In luk's ⊗, a #sup premise saturates to the
%% grid top k, counted inline by the NS term below.)
semiring_default_weight(aba,#sup).
semiring_default_weight(neutral,k).

#include "../defaults/base.lp".
#include "_phase.lp".

%% ---------------------------------------------------------------------------
%% CARRIER: [0, k]
%% ---------------------------------------------------------------------------
%% Unlike the other four algebras, Łukasiewicz is a semiring only on the GRID [0, k].
%% Machine-checked with Z3 (test/semiring_axioms.py): off the grid the ⊕-identity 0 stops
%% annihilating ⊗ (0 ⊗ 7 = 4 at k = 3), ⊗ stops being associative, and both identities fail on
%% the sentinels. No lifted top can repair it, because 0̄ = 0 is a FINITE value that must
%% annihilate -- making #sup absorbing, as arctic does (whose annihilator is #inf), would give
%% 0 ⊗ #sup = #sup.
%%
%% So `w : A → [0,k]` is a hypothesis of this algebra, checked at the boundary with the other
%% framework preconditions, not encoded here.

%% Bounded-sum ⊗ (both phases). #sum drops #sup/#inf, so saturate them first:
%% #inf -> 0 (the bounded-sum annihilator, precedence), #sup -> k (grid top).
luk_body_has_inf(P, R) :- body(R, B), pweight(P, B, #inf).

%% #inf is the bounded-sum ANNIHILATOR and takes precedence: the whole product is 0.
rule_deriv(P, R, X, 0) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    luk_body_has_inf(P, R).

%% Otherwise SUBSTITUTE each #sup premise by the grid top k and take the bounded sum.
%% (clingo's #sum silently drops #sup, so the NS*k term adds those premises back in.)
%% Substituting -- rather than short-circuiting the whole rule to k -- is what preserves
%% the otimes-IDENTITY law: k (x) w = max(0, k+w-k) = w, so an identity-valued premise
%% leaves its co-premises untouched instead of inflating the derivation to maximal strength.
%% Fold the body stepwise with the BINARY t-norm a(x)b = max(0, a+b-k), in the
%% body_first/body_next order (_phase.lp explains why the n-ary
%% max(0, S - (N-1)k) form, though equal on the carrier by associativity, cannot
%% sit inside the recursion). #sup is the (x)-identity's lift and enters the fold
%% as k, which is exactly what the old NS*k correction did; #inf zeroes the whole
%% rule via luk_body_has_inf above. Stepwise clamping equals the single end-clamp
%% only on the carrier [0,k] -- which is the only domain where this algebra is a
%% semiring at all (Z3, test/semiring_axioms.py), and validate.lp guards it.
luk_val(P, X, k) :- pweight(P, X, #sup).
luk_val(P, X, V) :- pweight(P, X, V), V != #sup, V != #inf.
luk_prefix(P, R, B, V) :- body_first(R, B), phase_triggered(P, R), luk_val(P, B, V).
luk_prefix(P, R, B2, V1+V2-k) :- body_next(R, B1, B2), luk_prefix(P, R, B1, V1),
    luk_val(P, B2, V2), V1 + V2 >= k.
luk_prefix(P, R, B2, 0) :- body_next(R, B1, B2), luk_prefix(P, R, B1, V1),
    luk_val(P, B2, V2), V1 + V2 < k.
rule_deriv(P, R, X, W) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    not luk_body_has_inf(P, R),
    body_last(R, B), luk_prefix(P, R, B, W).
