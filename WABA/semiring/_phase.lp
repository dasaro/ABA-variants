%% ============================================================================
%% _phase.lp — shared weight-propagation skeleton (algebra-agnostic part)
%% ============================================================================
%% Weight propagation as one parameterized computation pweight(Phase, X, W):
%%   support : weights over the selected (in) atoms          -> supported_with_weight/2
%%   maximal : weights over ALL assumptions                  -> arg_weight/2
%%
%% The maximal phase is INERT by default: the CLASSICAL defence semantics
%% (semantics/admissible.lp) are weight-blind and do not need it. It is switched on by
%% semantics/admissible.lp, which declares `budgeted_full` and supplies arg/1 +
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
%% Two bridges, not three. `phase_selected` used to gate the policy-default case while
%% `phase_active` gated the explicit-weight one, but they coincide exactly where the former was
%% used -- that rule is already restricted to `assumption(X)`, and for an ASSUMPTION:
%%   support : the flatness guard means an assumption is never a rule head, so `supported(X)`
%%             can only come from `in(X)`  ->  phase_active == phase_selected
%%   maximal : semantics/admissible.lp declares `arg(X) :- assumption(X).`, so arg(X) holds for
%%             every assumption  ->  phase_active == phase_selected
%% A `phase/1` domain predicate is gone with it: P was always bound by the phase_active literal
%% in the same body, so `phase(P)` was contributing neither safety nor a restriction.
%% support : weights over the in-set S          (always on)      -> supported_with_weight/2
%% maximal : weights over ALL assumptions       (budgeted_full)  -> arg_weight/2
%%              (the intrinsic strongest strength of an argument, used as a fixed attack cost)
phase_active(support, X)    :- supported(X).
phase_triggered(support, R) :- triggered_by_in(R).

%% maximal phase — gated on budgeted_full; every assumption is selected, so arg_weight is
%% the strength of an argument in the largest possible context (its intrinsic strongest form).
phase_active(maximal, X)    :- budgeted_full, arg(X).
phase_triggered(maximal, R) :- budgeted_full, arg_triggered(R).

%% ---- direct (own) weight: explicit weight, else policy default ---------------
%% Explicit weight is gated on phase_active (= in for flat assumptions, = supported
%% for non-flat / derived atoms — matches the previous per-semiring gating). The
%% policy default applies to unweighted assumptions that are selected.
direct_weight(P, X, V) :- weight(X, V), phase_active(P, X).
direct_weight(P, X, V) :- assumption(X), not weight(X, _), phase_active(P, X), default_assumption_weight(V).

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

%% ---- WHAT A WEIGHT IS A FUNCTION OF ------------------------------------------
%% pweight(P, X, W) is the ⊕-best over X's DERIVATION TREES, each folded with ⊗ over its rule
%% bodies. ⊗ therefore sees each leaf OCCURRENCE, so a leaf reached by two branches of one tree
%% is folded twice.
%%
%% Whether that matters is decided by ⊗'s IDEMPOTENCE, and the five algebras split
%% (machine-checked in test/semiring_axioms.py):
%%
%%   godel (⊗=min), bottleneck_cost (⊗=max)   IDEMPOTENT     duplicates collapse, so the weight
%%                                                            depends only on the SUPPORT SET
%%   tropical, arctic (⊗=+), lukasiewicz       NOT idempotent  the weight depends on the TREE
%%
%% Measured: two atoms with the identical support {f0=100, f1=200} but different tree shapes get
%% 100/100 under godel and 300/500 under tropical.
%%
%% This file DEFINES the weight over derivation trees. That is a deliberate choice, not an
%% oversight: it keeps the computation a semiring fold, which is what makes the whole algebra
%% story work. ABA's own arguments (S, c) carry a SET, so for the non-idempotent algebras
%% "the weight of an argument" is properly read as "the ⊕-best weight over the trees that
%% derive it". setsupport.lp offers the set-based alternative for callers who need it, at the
%% cost of leaving the fold behind.
%%
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
%% ---- ordered body positions (shared by the non-idempotent folds) -------------
%% A rule body is folded as an ORDERED sequence of binary (x) steps rather than by
%% one n-ary aggregate. The n-ary form is what the paper writes, and the two are
%% equal because (x) is associative and commutative -- but the n-ary #sum sits
%% inside the pweight/rule_deriv recursion, and gringo over-approximates a
%% RECURSIVE aggregate's possible values by the sums of ALL SUBSETS of its
%% possibly-true tuples. Along a derivation chain those candidate sets compound:
%% measured on a 2-premise chain, depth 5 grounds in 0.4 s and depth 6 exceeds
%% 20 s, for every (x) = sum algebra. min/max are immune (a subset's min IS one of
%% its elements, so candidates stay linear), which is why the idempotent algebras
%% never showed it. The binary fold keeps one candidate per (prefix, premise)
%% pair, restoring linear grounding on chains; these three predicates are
%% EDB-only, so they ground outside the recursive component.
body_first(R, B) :- rule(R), has_body(R), B = #min{ A : body(R,A) }.
body_next(R, B1, B2) :- body(R,B1), body(R,B2), B1 < B2,
                        B2 = #min{ A : body(R,A), A > B1 }.
body_last(R, B) :- rule(R), has_body(R), B = #max{ A : body(R,A) }.

supported_with_weight(X, W) :- pweight(support, X, W).
arg_weight(X, W)            :- pweight(maximal, X, W).
