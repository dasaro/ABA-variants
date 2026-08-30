%% WABA base logic: the part that is independent of the semiring (weight
%% propagation) and of the monoid (cost aggregation).
%%
%% Unary domain predicates (rule/1, is_head/1, has_body/1, derived_atom/1) exist to keep
%% grounding small by avoiding repeated existential patterns.
%%
%% Three well-formedness guards live here, and all three REJECT rather than warn:
%% flatness, acyclicity of derivations, and functionality of weight/2.

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
%% PRECONDITIONS ON THE FRAMEWORK — enforced at the BOUNDARY, not here
%% ====================
%% wABA is defined for a WELL-FORMED weighted flat ABA framework:
%%
%%   flat            no assumption is the head of a rule, so an assumption's weight is
%%                   intrinsic rather than extension-dependent
%%   acyclic         the rule-dependency graph has no cycle, so the ⊕-over-derivations /
%%                   ⊗-over-body recursion has a unique least fixpoint
%%   functional w    weight/2 is a partial FUNCTION on atoms
%%   w into S        every declared weight is an element of the algebra's carrier
%%   total/function c every assumption has exactly one contrary
%%   rule IDs        every body belongs to exactly one declared rule head
%%
%% These are hypotheses of the definition, not part of the semantics, and a paper states them
%% once rather than encoding each as a constraint. They used to be five guards plus their
%% helper predicates here; they now live where input is actually accepted -- bin/waba for the
%% CLI, runtime/config-service.js for the web playground -- which is also the only place that
%% can report WHICH atom is at fault instead of an unexplained UNSATISFIABLE.
%%
%% Nothing below assumes anything else about the framework: fed a malformed one, this file
%% computes the least fixpoint of the rules it was given, which is the honest answer.

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

%% Maximal argument context
%% ------------------------
%% The beta-sigma construction removes attacks BEFORE a candidate extension is
%% evaluated.  Its attack domain and weights must therefore be fixed independently
%% of that candidate.  `arg/1` is the least closure of the full assumption set and
%% `arg_weight/2` is the corresponding maximal-context propagation phase supplied by
%% semiring/_phase.lp.
%%
%% `budgeted_full` is the existing switch for that phase.  It is now enabled for
%% every supported semantics, rather than only for the former defence-specific
%% encoding.
budgeted_full.
arg(X) :- assumption(X).
arg(X) :- head(R,X), arg_triggered(R).
arg_triggered(R) :- rule(R), arg(Z) : body(R,Z).

%% Fixed atom-level attack relation.  Discarding (X,Y,W) removes the attack from
%% EVERY use made of it by the ordinary sigma semantics; it is not re-priced or
%% re-guessed for each candidate extension.
attacks_with_weight(X,Y,W) :- arg_weight(X,W), assumption(Y), contrary(Y,X).

%% One global attack-discard choice, shared by conflict-free, stable, admissible,
%% complete and preferred semantics.
{ discarded_attack(X,Y,W) : attacks_with_weight(X,Y,W) }.

%% Surviving attacks form the fixed reduced framework Att \ D.  This predicate is
%% deliberately independent of the candidate extension and is used by defence.
attack_survives_with_weight(X,Y,W) :-
    attacks_with_weight(X,Y,W), not discarded_attack(X,Y,W).

%% A candidate S successfully attacks Y when S derives X and X -> Y survives.
%% Conflict-free and stable semantics consume this candidate-relative view.
attacks_successfully_with_weight(X,Y,W) :-
    supported(X), attack_survives_with_weight(X,Y,W).

%% ====================
%% BUDGET
%% ====================
%% The budget is supplied ONLY by -c beta=N, through effective_budget/1. Earlier versions
%% asked frameworks to carry budget/1 facts; the supported input boundary now rejects them
%% because the framework language contains exactly five data predicates. Previously both a
%% fact and the caller's value survived, and the bound became min(N,beta) under ub, with
%% budget(0) silently disabling --beta altogether.
effective_budget(beta).

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
