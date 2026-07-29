%% WABA base logic: the part that is independent of the semiring (weight
%% propagation) and of the monoid (cost aggregation).
%%
%% Unary domain predicates (rule/1, is_head/1, has_body/1, derived_atom/1) exist to keep
%% grounding small by avoiding repeated existential patterns.
%%
%% Three well-formedness guards live here, and all three REJECT rather than warn:
%% flatness, well-foundedness of derivations, and functionality of weight/2.

%% ====================
%% DOMAIN PREDICATES
%% ====================
%% These unary predicates reduce grounding by avoiding repeated existential patterns

%% Rule meta-predicate (R is a rule identifier)
rule(R) :- head(R,_).

%% Unary flag: X appears as some rule head
is_head(X) :- head(_,X).

%% Unary flag: R has at least one body element
has_body(R) :- body(R,_).

%% Derived atoms: heads that are not assumptions
derived_atom(X) :- is_head(X), not assumption(X).

%% ====================
%% FUNCTIONALITY GUARD (weight/2 is a partial FUNCTION on atoms)
%% ====================
%% Two weight facts for the same atom make supported_with_weight/2 non-functional, which
%% splits ONE conflict into SEVERAL independently discardable attacks_with_weight/3 atoms.
%% The budget then double-charges, and there are answer sets in which the same
%% (attacker, target) conflict is simultaneously discarded AND successful. Rejected here
%% alongside the other two well-formedness conditions rather than silently mis-costed.
multi_weight(X) :- weight(X,V1), weight(X,V2), V1 != V2.
:- multi_weight(_).

%% ====================
%% FLATNESS GUARD
%% ====================
%% WABA's weighted/budgeted semantics is defined for FLAT ABA frameworks: no
%% assumption may be the head of a rule. (The weight of an assumption is then
%% intrinsic, not extension-dependent; this matches the established ABA theory the
%% semantics rest on, and weighted non-flat ABA has no settled semantics.)
%% A non-flat assumption is flagged here and the framework is rejected outright,
%% rather than silently producing ill-defined weights.
non_flat_assumption(X) :- assumption(X), is_head(X).
:- non_flat_assumption(_).

%% ====================
%% WELL-FOUNDEDNESS GUARD (acyclic derivations)
%% ====================
%% The semiring weight of a derived atom is ⊕ over its derivations, each ⊗ over a rule
%% body — well-defined only when the rule-dependency graph is ACYCLIC. A derivation cycle
%% (p <- q, q <- p) admits an unfounded second fixpoint in which the cyclic atom floats in
%% at the ⊗-identity, yielding spurious weights (and, under the cost semirings, spurious
%% free-discard extensions). Such frameworks are rejected outright, like non-flat ones,
%% rather than silently producing ill-defined weights. (WABA is defined for well-founded
%% flat frameworks; the curated/reference examples are all acyclic.)
derivation_edge(H,B) :- head(R,H), body(R,B).
derivation_reaches(X,Y) :- derivation_edge(X,Y).
derivation_reaches(X,Z) :- derivation_edge(X,Y), derivation_reaches(Y,Z).
derivation_cycle(X) :- derivation_reaches(X,X).
:- derivation_cycle(_).

%% ====================
%% CORE LOGIC
%% ====================

%% Support computation (weight-independent)
%% An atom is supported if:
%% 1. It's an assumption that is in, OR
%% 2. There exists a rule with this atom as head and all body elements are supported
supported(X) :- assumption(X), in(X).
supported(X) :- head(R,X), triggered_by_in(R).

%% A rule is triggered when all its body elements are supported
%% OPTIMIZED: Use rule(R) instead of head(R,_) for domain
triggered_by_in(R) :- rule(R), supported(X) : body(R,X).

%% Attack computation
%% An attack exists when a supported atom X attacks an assumption Y
%% (where Y's contrary is X), with the weight of X
%% OPTIMIZED: Remove redundant supported(X) check (supported_with_weight(X,W) implies support)
attacks_with_weight(X,Y,W) :- supported_with_weight(X,W), assumption(Y), contrary(Y,X).

%% Attack discretion choice
%% We can choose to discard any attack (at a cost)
{ discarded_attack(X,Y,W) : attacks_with_weight(X,Y,W) }.

%% Successful attacks
%% An attack succeeds if it's not discarded
attacks_successfully_with_weight(X,Y,W) :- attacks_with_weight(X,Y,W), not discarded_attack(X,Y,W).

%% ====================
%% DIAGNOSTIC (advisory — NOT a constraint; never rejects an answer set)
%% ====================
%% Flags an explicit weight/2 placed on a DERIVED atom (a rule head) whose propagated
%% support weight ends up DIFFERENT from the declared one — i.e. the declared weight did
%% not take effect. In WABA weights belong on the LEAVES (assumptions / facts) and derived
%% atoms get their weight by PROPAGATION; an explicit weight on a derived atom is combined
%% with its derivation via the semiring's ⊕, and is SILENTLY dominated in several algebras
%% (Gödel/Bottleneck/Łukasiewicz drive it to the ⊗-identity #sup/#inf/k). This predicate is
%% empty for a framework that keeps its weights on the leaves; the filter modules #show
%% it so a modeller sees it. It is ADVISORY: a framework that trips it still solves.
%% See README.md, "Where weights live (leaves vs derived atoms)".
weight_on_derived_dominated(X, Declared, Effective) :-
    weight(X, Declared), derived_atom(X),
    supported_with_weight(X, Effective), Effective != Declared.

%% ====================
%% BUDGET
%% ====================
%% Set with -c beta=N. This fact is ALWAYS added, so a framework that also states
%% budget(N) does NOT override it: both facts survive, and constraint/ub.lp and lb.lp
%% quantify over budget(B). The effective bound is therefore min(N,beta) under ub and
%% max(N,beta) under lb. To let a framework own its budget, pass -c beta with the same N.
budget(beta).

%% An unbound `beta` is not "budget disabled": clingo orders every integer strictly BELOW
%% an uninterpreted constant, so `C > beta` never holds (ub silently unbounded) and
%% `C < beta` always holds (lb silently collapses to no_discard). Both fail silently and in
%% opposite directions, so constraint/ub.lp and constraint/lb.lp reject that composition.
%% The check lives THERE, not here, so that runs which load no budget module do not ground
%% its arithmetic and do not emit clingo's "operation undefined" info.

%% Budget enforcement modules (choose exactly one):
%% - constraint/ub.lp         upper bound: reject when the aggregate EXCEEDS beta
%% - constraint/lb.lp         lower bound: reject when the aggregate is BELOW beta
%% - constraint/no_discard.lp forbid every discard (exact classical ABA recovery)
