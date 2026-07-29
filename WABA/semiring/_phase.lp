%% ============================================================================
%% _phase.lp — shared weight-propagation skeleton (algebra-agnostic part)
%% ============================================================================
%% Weight propagation as one parameterized computation pweight(Phase, X, W):
%%   support : weights over the selected (in) atoms          -> supported_with_weight/2
%%   maximal : weights over ALL assumptions                  -> arg_weight/2
%%
%% The maximal phase is INERT by default: the CLASSICAL defence semantics
%% (semantics/admissible.lp) are weight-blind and do not need it. It is switched on by
%% semantics/admissible_dunne.lp, which declares `budgeted_full` and supplies arg/1 +
%% arg_triggered/1; arg_weight is then each attacker's strength in the maximal argument
%% context, used as a fixed (extension-independent) attack cost.
%%
%% A third phase, `undefeated`, existed for an earlier budgeted-defence encoding
%% (semantics/admissible_budgeted.lp) that priced attacks over the not-defeated set.
%% Both were retired on 2026-07-29: that design budgeted defence but never internal
%% conflict, so it was not the Dunne Def 6 lift the paper defines.
%%
%% A concrete algebra is fixed by a thin shim that declares:
%%   oplus(min|max)      -- ⊕ combine of alternative derivations
%%   otimes_identity(I)  -- 1̄ (empty-body / fact weight)
%% and includes a ⊗ skeleton (_idempotent.lp or _additive.lp) defining rule_deriv/4.

%% ---- phase bridges -----------------------------------------------------------
%% support : weights over the in-set S          (always on)      -> supported_with_weight/2
%% maximal : weights over ALL assumptions       (budgeted_full)  -> arg_weight/2
%%              (the intrinsic strongest strength of an argument, used as a fixed attack cost)
phase(support).
phase(maximal) :- budgeted_full.

phase_active(support, X)    :- supported(X).
phase_triggered(support, R) :- triggered_by_in(R).
%% "selected" = the assumption is committed in this phase (in).
phase_selected(support, X)  :- in(X).

%% maximal phase — gated on budgeted_full; every assumption is selected, so arg_weight is
%% the strength of an argument in the largest possible context (its intrinsic strongest form).
phase_active(maximal, X)    :- budgeted_full, arg(X).
phase_triggered(maximal, R) :- budgeted_full, arg_triggered(R).
phase_selected(maximal, X)  :- budgeted_full, assumption(X).

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

%% ---- expose the phases under their conventional names ------------------------
supported_with_weight(X, W) :- pweight(support, X, W).
arg_weight(X, W)            :- pweight(maximal, X, W).
