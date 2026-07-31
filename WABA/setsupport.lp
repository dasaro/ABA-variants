%% ============================================================================
%% setsupport.lp — weight over the SUPPORT SET, not the derivation tree
%% ============================================================================
%% OPTIONAL. The core defines an atom's weight as the ⊕-best over its derivation TREES, each
%% folded with ⊗ over rule bodies (see semiring/_phase.lp). For the two idempotent algebras
%% (godel ⊗=min, bottleneck_cost ⊗=max) that already depends only on the support SET, because
%% duplicates collapse. For the additive ones it does not: a leaf reached by two branches of one
%% tree is folded twice, so two atoms with identical support can carry different weights, and the
%% probabilistic (tropical) reading multiplies a reused fact as if it were independent of itself.
%%
%% This module computes the other quantity:
%%
%%     min over derivation trees T of q  of  ⊗ over the DISTINCT leaves of T
%%
%% WHY IT IS NOT A SEMIRING FOLD, and why that is the whole point.
%% A fold cannot do this. Folding is bottom-up and local: at each rule it sees its premises'
%% VALUES, not which leaves produced them, so it cannot tell a leaf it has already counted from a
%% new one. Recovering that needs the identity of the support, which is provenance/lineage
%% information -- exactly what ProbLog compiles into an SDD/BDD instead of folding. So the price
%% of set semantics is leaving the algebra behind:
%%
%%   * a CHOICE of one triggered rule per supported derived atom -- i.e. pick a proof tree
%%   * the leaves of that chosen tree, collected top-down from the query
%%   * a ⊗-fold over those leaves as a SET (#sum over distinct L, #min/#max are already
%%     set-insensitive)
%%   * an optimisation over the choice, because ⊕ can no longer be a local aggregate
%%
%% That turns one grounding pass into a search, which is the cost the comparison reports.
%%
%% USAGE   clingo -n 0 --opt-mode=opt core/base.lp semiring/<s>.lp defaults/<d>.lp \
%%                constraint/no_discard.lp semantics/cf.lp setsupport.lp <framework.lp> \
%%                -c beta=0
%%         plus a `query_atom(q).` fact naming the atom to weigh. The LAST set_weight/1 printed
%%         is the answer.
%%
%%         `-n 0` IS REQUIRED, and this is a real trap: the value here comes from an
%%         OPTIMISATION, not from an aggregate, so `-n 1` stops at the first model and reports
%%         an arbitrary proof rather than the best one. Measured on a 5-leaf framework: -n 1
%%         gave 52, the optimum is 20. clingo says `Optimization:` either way and only prints
%%         `OPTIMUM FOUND` in the second case -- so check for that line, not just for output.
%% ============================================================================

%% Pick one derivation per supported derived atom. Atoms outside the chosen proof are picked
%% too and simply go unused; constraining the choice to the proof would be circular.
1 { proof_rule(X, R) : head(R, X), triggered_by_in(R) } 1 :- derived_atom(X), supported(X).

%% The chosen tree, walked down from the query.
in_proof(Q) :- query_atom(Q).
in_proof(B) :- in_proof(X), proof_rule(X, R), body(R, B).

%% Its SUPPORT SET: the assumptions it rests on, each once however often it is reached.
support_leaf(L) :- in_proof(L), assumption(L), in(L).

%% ⊗ over the set. #sum ranges over DISTINCT (V, L) tuples, so a leaf reached twice contributes
%% once -- that single change is the whole difference from the tree fold. #min/#max are already
%% insensitive to multiplicity, so the idempotent algebras agree with the core by construction,
%% which is a useful self-check: on those two, set_weight must equal supported_with_weight.
set_weight(W) :- otimes(min), W = #min{ V,L : support_leaf(L), pweight(support, L, V) }.
set_weight(W) :- otimes(max), W = #max{ V,L : support_leaf(L), pweight(support, L, V) }.
set_weight(W) :- not otimes(min), not otimes(max),
                 W = #sum{ V,L : support_leaf(L), pweight(support, L, V) }.

%% ⊕ over the alternative trees, as an OPTIMISATION rather than an aggregate: the choice above
%% fixes one tree per answer set, so the best is found by optimising across answer sets.
#minimize { W@0 : set_weight(W), oplus(min) }.
#maximize { W@0 : set_weight(W), oplus(max) }.

#show set_weight/1.
#show support_leaf/1.
