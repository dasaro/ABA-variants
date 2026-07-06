%% Łukasiewicz / bounded-sum semiring (outside the godel/tropical 2×2).
%% Semiring: ({0..k}, ⊕=max, ⊗=max(0, a+b-k), 0̄=0, 1̄=k) — strength polarity.
%% n-ary ⊗: max(0, (Σ wi) - (n-1)*k). Unlike Gödel's weakest-link, a chain of weak
%% premises ERODES certainty toward 0. The only ⊗ that is not min, max or plain +,
%% so it shares _phase.lp's propagation skeleton but supplies its own rule_deriv/4.
%% Weights live on the integer grid {0..k} (#const k, default 1000); override -c k=N.

#const k = 1000.

active_semiring(lukasiewicz).

oplus(max).
oplus_identity(0).
otimes_identity(k).

semiring_default_weight(legacy,k).
%% aba default is #sup (un-discardable): an unweighted assumption then behaves as a
%% plain ABA assumption whose attack survives any finite budget, so β=0 / no_discard
%% recovers classical ABA at every k. (In luk's ⊗, a #sup premise saturates to the
%% grid top k; see the luk_body_has_sup case below.)
semiring_default_weight(aba,#sup).
semiring_default_weight(neutral,k).

#include "../defaults/base.lp".
#include "_phase.lp".

%% Bounded-sum ⊗ (both phases). #sum drops #sup/#inf, so saturate them first:
%% #inf -> 0 (the bounded-sum annihilator, precedence), #sup -> k (grid top).
luk_body_has_sup(P, R) :- body(R, B), pweight(P, B, #sup).
luk_body_has_inf(P, R) :- body(R, B), pweight(P, B, #inf).

rule_deriv(P, R, X, 0) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    luk_body_has_inf(P, R).
rule_deriv(P, R, X, k) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    not luk_body_has_inf(P, R), luk_body_has_sup(P, R).
rule_deriv(P, R, X, M) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    not luk_body_has_inf(P, R), not luk_body_has_sup(P, R),
    S = #sum{ V,B : body(R,B), pweight(P,B,V) },
    N = #count{ B : body(R,B) },
    M = #max{ 0 ; S-(N-1)*k }.
