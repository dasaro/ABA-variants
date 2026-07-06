%% ============================================================================
%% _phase.lp — shared weight-propagation skeleton (algebra-agnostic part)
%% ============================================================================
%% Weight propagation over the selected (in) atoms as one parameterized
%% computation pweight(Phase, X, W):
%%   support : weights over the selected (in) atoms -> supported_with_weight/2
%%
%% (Defense semantics — admissible/complete/grounded/preferred — are CLASSICAL and
%% weight-blind: they use the not-defeated SET directly, so no weight phase is run
%% for them. See semantics/admissible.lp.)
%%
%% A concrete algebra is fixed by a thin shim that declares:
%%   oplus(min|max)      -- ⊕ combine of alternative derivations
%%   otimes_identity(I)  -- 1̄ (empty-body / fact weight)
%% and includes a ⊗ skeleton (_idempotent.lp or _additive.lp) defining rule_deriv/4.

%% ---- phase bridges -----------------------------------------------------------
phase(support).

phase_active(support, X)    :- supported(X).
phase_triggered(support, R) :- triggered_by_in(R).
%% "selected" = the assumption is committed in this phase (in).
phase_selected(support, X)  :- in(X).

%% ---- direct (own) weight: explicit weight, else policy default ---------------
%% Explicit weight is gated on phase_active (= in for flat assumptions, = supported
%% for non-flat / derived atoms — matches the previous per-semiring gating). The
%% policy default applies to unweighted assumptions that are selected.
direct_weight(P, X, V) :- phase(P), weight(X, V), phase_active(P, X).
direct_weight(P, X, V) :- phase(P), assumption(X), not weight(X, _), phase_selected(P, X), default_assumption_weight(V).

%% ---- assumptions: weight is just the direct weight --------------------------
%% WABA is restricted to flat ABA (see core/base.lp's flatness guard), so an
%% assumption is never a rule head — its weight is intrinsic, with no rule-derived
%% alternative to combine.
pweight(P, X, W) :- assumption(X), direct_weight(P, X, W).

%% ---- empty-body rule (fact) = empty conjunction = ⊗-identity 1̄ ---------------
%% Guarded by `not weight(X,_)` so an explicitly weighted fact keeps its weight.
rule_deriv(P, R, X, I) :-
    phase_active(P, X), rule(R), head(R, X), not has_body(R), not weight(X, _),
    otimes_identity(I).

%% ---- derived atoms: combine alternative derivations + explicit weight via ⊕ --
%% clingo #max keeps #sup / drops #inf and #min keeps #inf / drops #sup, which is
%% exactly the ⊕ identity (max-identity #inf, min-identity #sup), so no special
%% infinity handling is needed for the combine itself.
pweight(P, X, W) :-
    oplus(max), derived_atom(X), phase_active(P, X),
    W = #max{ V,R : rule_deriv(P,R,X,V) ; V : direct_weight(P,X,V) }.
pweight(P, X, W) :-
    oplus(min), derived_atom(X), phase_active(P, X),
    W = #min{ V,R : rule_deriv(P,R,X,V) ; V : direct_weight(P,X,V) }.

%% ---- expose the support phase under its conventional name --------------------
supported_with_weight(X, W) :- pweight(support, X, W).
