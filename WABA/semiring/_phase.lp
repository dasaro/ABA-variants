%% ============================================================================
%% _phase.lp — shared weight-propagation skeleton (algebra-agnostic part)
%% ============================================================================
%% Folds the support-phase and undefeated-phase weight propagations into ONE
%% parameterized computation pweight(Phase, X, W):
%%   support    : weights over the selected (in) atoms        -> supported_with_weight/2
%%   undefeated : weights over the not-defeated atoms         -> undefeated_weight/2
%%                (only populated when a defense semantics, e.g. semantics/admissible.lp,
%%                 defines derived_from_undefeated/1 + triggered_by_undefeated/1)
%%
%% A concrete algebra is fixed by a thin shim that declares:
%%   oplus(min|max)                       -- ⊕ combine of alternative derivations
%%   otimes_identity(I)                   -- 1̄ (empty-body / fact weight)
%%   affordability_polarity(strength|cost)
%% and includes a ⊗ skeleton (_idempotent.lp or _additive.lp) defining rule_deriv/4.

%% ---- phase bridges -----------------------------------------------------------
phase(support).
phase(undefeated).

phase_active(support, X)       :- supported(X).
phase_active(undefeated, X)    :- derived_from_undefeated(X).
phase_triggered(support, R)    :- triggered_by_in(R).
phase_triggered(undefeated, R) :- triggered_by_undefeated(R).
%% "selected" = the assumption is committed in this phase (in / not-defeated). The
%% undefeated form is gated by derived_from_undefeated, so the whole undefeated
%% phase is inert (no extra grounding) unless a defense semantics is loaded.
phase_selected(support, X)     :- in(X).
phase_selected(undefeated, X)  :- assumption(X), derived_from_undefeated(X).

%% ---- direct (own) weight: explicit weight, else policy default ---------------
%% Explicit weight is gated on phase_active (= in for flat assumptions, = supported
%% for non-flat / derived atoms — matches the previous per-semiring gating). The
%% policy default applies to unweighted assumptions that are selected.
direct_weight(P, X, V) :- phase(P), weight(X, V), phase_active(P, X).
direct_weight(P, X, V) :- phase(P), assumption(X), not weight(X, _), phase_selected(P, X), default_assumption_weight(V).

%% ---- flat atoms (not a rule head): weight is just the direct weight -----------
pweight(P, X, W) :- not is_head(X), direct_weight(P, X, W).

%% ---- empty-body rule (fact) = empty conjunction = ⊗-identity 1̄ ---------------
%% Guarded by `not weight(X,_)` so an explicitly weighted fact keeps its weight.
rule_deriv(P, R, X, I) :-
    phase_active(P, X), rule(R), head(R, X), not has_body(R), not weight(X, _),
    otimes_identity(I).

%% ---- combine alternative derivations + direct weight via ⊕ (head atoms) ------
%% clingo #max keeps #sup / drops #inf and #min keeps #inf / drops #sup, which is
%% exactly the ⊕ identity (max-identity #inf, min-identity #sup), so no special
%% infinity handling is needed for the combine itself.
pweight(P, X, W) :-
    oplus(max), is_head(X), phase_active(P, X),
    W = #max{ V,R : rule_deriv(P,R,X,V) ; V : direct_weight(P,X,V) }.
pweight(P, X, W) :-
    oplus(min), is_head(X), phase_active(P, X),
    W = #min{ V,R : rule_deriv(P,R,X,V) ; V : direct_weight(P,X,V) }.

%% ---- expose the two phases under their conventional names --------------------
supported_with_weight(X, W) :- pweight(support, X, W).
undefeated_weight(X, W)     :- pweight(undefeated, X, W).

%% ---- attack affordability for defense semantics (polarity-parameterized) -----
unaffordable_attack(W, B) :- affordability_polarity(strength), undefeated_weight(_, W), budget(B), B = #sup, W != #sup.
unaffordable_attack(W, B) :- affordability_polarity(strength), undefeated_weight(_, W), budget(B), B = 0,     W != #inf.
unaffordable_attack(W, B) :- affordability_polarity(strength), undefeated_weight(_, W), budget(B), B != #sup, B != 0, W < B.
unaffordable_attack(W, B) :- affordability_polarity(cost),     undefeated_weight(_, W), budget(B), B = 0,     W != #inf.
unaffordable_attack(W, B) :- affordability_polarity(cost),     undefeated_weight(_, W), budget(B), B != 0,    W > B.
