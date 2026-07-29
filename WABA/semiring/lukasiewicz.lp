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

%% #inf is the bounded-sum ANNIHILATOR and takes precedence: the whole product is 0.
rule_deriv(P, R, X, 0) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    luk_body_has_inf(P, R).

%% Otherwise SUBSTITUTE each #sup premise by the grid top k and take the bounded sum.
%% (clingo's #sum silently drops #sup, so the NS*k term adds those premises back in.)
%% Substituting -- rather than short-circuiting the whole rule to k -- is what preserves
%% the otimes-IDENTITY law: k (x) w = max(0, k+w-k) = w, so an identity-valued premise
%% leaves its co-premises untouched instead of inflating the derivation to maximal strength.
rule_deriv(P, R, X, M) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    not luk_body_has_inf(P, R),
    S  = #sum{ V,B : body(R,B), pweight(P,B,V) },
    NS = #count{ B : body(R,B), pweight(P,B,#sup) },
    N  = #count{ B : body(R,B) },
    M  = #max{ 0 ; S + NS*k - (N-1)*k }.
