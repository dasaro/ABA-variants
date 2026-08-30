%% ============================================================================
%% validate.lp — the framework preconditions, as a SEPARATE pre-flight program
%% ============================================================================
%% wABA is defined for a well-formed weighted flat ABA framework. Those conditions are
%% hypotheses of the definition, not part of the semantics, so they are not in core/base.lp:
%% a paper states them once, and the core computes the mathematics.
%%
%% The supported entry points first apply a conservative source parser: only ground facts over
%% the five public predicates, comments, constants and (in the CLI) recursively checked includes
%% cross that boundary. This prevents a framework from defining candidate-dependent weights,
%% runtime predicates, constraints or solver directives. The parser understands pooled and
%% multi-line facts, block comments, function terms and quoted strings.
%%
%% The mathematical conditions below are then checked HERE, by clingo, on those facts alone.
%% Grounding a framework against this file is cheap: there is no choice rule and no search.
%%
%% USAGE   clingo --outf=0 validate.lp <framework.lp>            [-c k=N for lukasiewicz]
%%         Any violation/2 atom in the answer set is a rejection; the empty answer set means
%%         the framework is well formed. Callers report the atom, which is what an in-core
%%         constraint could never do -- it could only return UNSATISFIABLE.
%% ============================================================================

#const k = 0.                  %% overridden with -c k=N when the Lukasiewicz carrier applies

%% ---- rule identifiers denote exactly one rule --------------------------------
%% One identifier joins one head to zero or more body atoms. Reusing it for two heads gives both
%% heads the same body, so the facts no longer encode the promised one-ID/one-rule translation;
%% a body with no head is silently inert. Either case makes reconstruction non-lossless.
has_head(R) :- head(R, _).
violation(multi_head, R) :- head(R, X), head(R, Y), X != Y.
violation(orphan_body, R) :- body(R, _), not has_head(R).

%% ---- flat: no assumption is the head of a rule -------------------------------
%% An assumption's weight is then intrinsic rather than extension-dependent, which is what the
%% propagation assumes. Weighted non-flat ABA has no settled semantics.
violation(not_flat, X) :- assumption(X), head(_, X).

%% ---- well-founded: the rule-dependency graph is acyclic ----------------------
%% A derived atom's weight is ⊕ over its derivations, each ⊗ over a rule body; that recursion
%% has a unique least fixpoint only on a DAG. A cycle admits an unfounded second fixpoint in
%% which the cyclic atom floats in at the ⊗-identity.
reaches(X, Y) :- head(R, X), body(R, Y).
reaches(X, Z) :- head(R, X), body(R, Y), reaches(Y, Z).
violation(cyclic, X) :- reaches(X, X).

%% ---- w is a partial FUNCTION on atoms ----------------------------------------
%% Two weights for one atom split ONE conflict into several independently discardable attacks:
%% the budget double-charges, and the same (attacker, target) pair can be discarded AND
%% successful in one answer set. Stated over weight/2 however it is DERIVED, so a rule-defined
%% weight colliding with a fact is caught too.
violation(multi_weight, X) :- weight(X, V), weight(X, W), V != W.

%% ---- contrary is a total FUNCTION on assumptions ----------------------------
%% The ABA signature requires exactly one contrary for every assumption.  Missing
%% declarations silently turn an assumption into an unattacked atom; multiple declarations
%% create more than one atomic attack unit for one target and invalidate |T_F| <= |A|.
has_contrary(X) :- assumption(X), contrary(X, _).
violation(missing_contrary, X) :- assumption(X), not has_contrary(X).
violation(multi_contrary, X) :- assumption(X), contrary(X, C), contrary(X, D), C != D.

%% ---- w maps into the algebra's carrier ---------------------------------------
%% A non-integral weight is silently dropped by the monoid aggregates (#sum/#max/#min ignore a
%% non-integral tuple), so its attack costs nothing and is discardable at any budget. The two
%% infinity sentinels stay legal: they are semiring identities, and the budget guards handle
%% both ends explicitly.
integral(X) :- weight(X, W), W = W + 0.
sentinel(X)  :- weight(X, #sup).
sentinel(X)  :- weight(X, #inf).
violation(not_a_number, X) :- weight(X, _), not integral(X), not sentinel(X).
violation(negative, X)     :- weight(X, W), W = W + 0, W < 0.

%% ---- Lukasiewicz only: the carrier is [0, k] ---------------------------------
%% Z3 refutes the annihilator law, associativity and both identities off the grid
%% (test/semiring_axioms.py). Checked only when the caller passes -c k=N, since k is meaningless
%% for the other four algebras; callers MUST pass the same k they will give the solver, which is
%% the module's own default when the user did not choose one.
violation(off_grid, X) :- k > 0, weight(X, W), W = W + 0, W > k.
violation(off_grid, X) :- k > 0, weight(X, #sup).
violation(off_grid, X) :- k > 0, weight(X, #inf).

%% ---- ADVISORY: does any derivation reuse a leaf? -----------------------------
%% Not a violation -- a framework like this is perfectly well formed. It is reported because it
%% is exactly the condition under which the two non-idempotent readings stop coinciding:
%%
%%   * the probabilistic (tropical) reading multiplies a reused fact twice, i.e. treats it as
%%     independent of itself, so it UNDER-estimates the most-probable proof
%%   * two atoms with the same support SET can get different weights, since ⊗ folds occurrences
%%
%% Under godel / bottleneck_cost (⊗ idempotent) it makes no difference at all.
%% An over-approximation: `supports` unions over alternative derivations, so this can flag a
%% framework in which no SINGLE tree actually reuses a leaf. It is a warning, not a rejection.
supports(X, X) :- assumption(X).
supports(X, L) :- head(R, X), body(R, B), supports(B, L).
advisory(leaf_reuse, X) :- head(R, X), body(R, B1), body(R, B2), B1 < B2,
                           supports(B1, L), supports(B2, L).

%% ---- wrapper-surface policy (OFF by default) ---------------------------------
%% Distinct from everything above: #sup and #inf ARE elements of four of the five carriers, so
%% they are mathematically fine and core/base.lp accepts them. But bin/waba and the playground
%% normalise their authored surface to FINITE nonnegative integers, because an infinite leaf
%% weight is almost always a modelling slip rather than an intent. That is a surface decision,
%% not a precondition of the definition, so it is a switch the caller turns on rather than
%% something baked in -- raw clingo composition stays unrestricted.
#const finite_only = 0.
violation(not_finite, X) :- finite_only = 1, weight(X, #sup).
violation(not_finite, X) :- finite_only = 1, weight(X, #inf).

#show violation/2.
#show advisory/2.
