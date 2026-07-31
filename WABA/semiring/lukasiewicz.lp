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
%% CARRIER GUARD — Łukasiewicz is a semiring only on [0, k]
%% ---------------------------------------------------------------------------
%% Machine-checked with Z3 over the domain core/base.lp actually admits (ℤ ∪ {#inf,#sup}):
%% godel, bottleneck_cost, tropical and arctic satisfy all eight commutative-semiring axioms
%% there, but Łukasiewicz satisfies only three. Restricted to [0,k] it satisfies all eight.
%% The three that fail outside it, with the counterexamples Z3 returned:
%%
%%   0̄ annihilates ⊗   a = 7, k = 3     0 ⊗ 7 = max(0, 0+7-3) = 4, not 0
%%   ⊗ associative      a = -7, b = c = 6, k = 5
%%   ⊗ identity / ⊕ identity for a = #sup or #inf
%%
%% Verified in clingo, not just in the model: with k=3 and weights 0 and 7 the implementation
%% reports supported_with_weight(x,4) for the rule body {0,7}, where the algebra requires 0.
%%
%% Unlike the other four, Łukasiewicz's ⊕-identity 0̄ = 0 is a FINITE value that must annihilate
%% ⊗. That is why no lifted top can be added to the carrier: making #sup absorbing (as arctic
%% does, whose annihilator is #inf) would give 0 ⊗ #sup = #sup and break the annihilator law.
%%
%% So every DECLARED weight must lie on the grid. This is the same class of guard as
%% core/base.lp's integrality and functionality checks, and it REJECTS rather than warns:
%% off-grid weights do not merely look odd, they make ⊗ non-associative, so the value a
%% derivation gets would depend on how its rules happened to be written.
weight_off_grid(X) :- weight(X, W), W = W + 0, W < 0.
weight_off_grid(X) :- weight(X, W), W = W + 0, W > k.
weight_off_grid(X) :- weight(X, #sup).
weight_off_grid(X) :- weight(X, #inf).
:- weight_off_grid(_).

%% δ is deliberately NOT covered by that guard. `--default-policy aba` sets δ = #sup, which is
%% an EXTERNAL marker meaning "this objection may never be paid for" (semantics/admissible.lp
%% keys on arg_weight(X,#sup)), not an element of [0,k]. Inside a rule body ⊗ substitutes it by
%% the grid top k = 1̄, so it is transparent in a conjunction rather than inflating it. The
%% consequence, which is a genuine property of a BOUNDED algebra rather than a defect, is that
%% δ = #sup is un-droppable only at the leaf: it cannot make a derived objection un-droppable,
%% because [0,k] has no absorbing top. Use ABA recovery (constraint/no_discard.lp) when
%% un-droppability must hold throughout.

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
rule_deriv(P, R, X, M) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    not luk_body_has_inf(P, R),
    S  = #sum{ V,B : body(R,B), pweight(P,B,V) },
    NS = #count{ B : body(R,B), pweight(P,B,#sup) },
    N  = #count{ B : body(R,B) },
    M  = #max{ 0 ; S + NS*k - (N-1)*k }.
