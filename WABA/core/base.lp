%% WABA Base Logic (Semiring/Monoid-Independent) - GROUNDING OPTIMIZED
%% This file contains the core argumentation logic that is independent
%% of the choice of semiring (weight propagation) and monoid (cost aggregation).
%%
%% OPTIMIZATIONS APPLIED:
%% - Added unary domain predicates to reduce grounding size
%% - Use rule/1 consistently instead of head(R,_)
%% - Removed redundant supported(X) joins

%% Budget constant used by the supported CLI wrapper and by raw clingo runs.
%% Framework files may also state budget(beta); duplicate identical facts are harmless.

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
%% empty for a well-formed framework; the filter modules #show it so a modeller sees it.
%% See README.md, "Where weights live (leaves vs derived atoms)".
weight_on_derived_dominated(X, Declared, Effective) :-
    weight(X, Declared), derived_atom(X),
    supported_with_weight(X, Effective), Effective != Declared.

%% ====================
%% BUDGET CONSTRAINT
%% ====================
%% Budget Constraints
%% ====================
%%
%% Budget value is typically set via command line: -c beta=N
budget(beta).

%% Budget constraints are in constraint/ directory.
%% `constraint/ub.lp` and `constraint/lb.lp` read the aggregate family from
%% the loaded monoid module.
%%
%% Load appropriate constraint file for budget enforcement:
%% - constraint/ub.lp - Upper bound for the active monoid family (cost ≤ beta)
%% - constraint/lb.lp - Lower bound for the active monoid family (cost ≥ beta)
%% - constraint/no_discard.lp - Plain ABA mode (no attack discarding)
