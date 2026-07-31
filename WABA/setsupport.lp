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
%% WHY IT IS NOT A SEMIRING FOLD. Folding is bottom-up and local: at each rule it sees its
%% premises' VALUES, not which leaves produced them, so it cannot tell a leaf it has already
%% counted from a new one. Recovering that needs the identity of the support — provenance —
%% which is what ProbLog compiles into an SDD/BDD instead of folding. So the price of set
%% semantics is leaving the algebra behind: a CHOICE of one triggered rule per supported derived
%% atom (= pick a proof tree), the leaves of that tree collected top-down from the query, and an
%% optimisation over the choice, because ⊕ can no longer be a local aggregate. In the worst case
%% that optimisation is NP-hard — minimum set cover embeds directly: one rule alternative per
%% covering set, distinct-leaf cost = number of sets used — where the tree fold stays
%% polynomial. That is the INTRINSIC cost of this mode.
%%
%% WHAT IS NOT PAID ANY MORE. The first version also bound the sum to a term,
%%     set_weight(W) :- ..., W = #sum{ V,L : support_leaf(L), ... }.
%% support_leaf depends on the proof choice, so gringo had to ground one candidate value per
%% ACHIEVABLE SUBSET SUM of the leaf weights — pseudo-polynomial value enumeration that dwarfed
%% the actual search. Measured on 120 facts / 32 proofs: 10.5 s wall, of which only 0.36 s was
%% solving (150 choices, 14 conflicts); the same optimum and the same OPTIMUM FOUND certificate
%% take 0.04 s when the sum lives only in the objective, as one tuple per leaf that the solver
%% sums natively. Hence the split below:
%%
%%   * idempotent ⊗ (min/max): set_weight/1 stays an atom — a min/max aggregate's possible
%%     values are just its elements, so it grounds linearly;
%%   * additive ⊗ (plain +): the sum lives ONLY in #minimize/#maximize tuples; read the
%%     optimum from clingo's `Optimization` line (negated by clingo for a maximize objective);
%%   * clamped ⊗ (lukasiewicz, max(0,a+b-k)): REJECTED below. max(0, Σ - (n-1)k) is not a sum
%%     of per-leaf terms, so it is not tuple-separable — and the previous silent fallback to a
%%     plain Σ computed the wrong algebra for it.
%%
%% USAGE   clingo -n 0 --opt-mode=opt core/base.lp semiring/<s>.lp defaults/<d>.lp \
%%                constraint/no_discard.lp semantics/cf.lp setsupport.lp <framework.lp> \
%%                -c beta=0
%%         plus a `query_atom(q).` fact naming the atom to weigh.
%%
%%         `-n 0` IS REQUIRED, and this is a real trap: the value comes from an OPTIMISATION,
%%         so `-n 1` stops at the first model and reports an arbitrary proof rather than the
%%         best one (measured: 52 where the optimum is 20). Check for `OPTIMUM FOUND`, then
%%         read the LAST `Optimization` value — or set_weight/1 under an idempotent ⊗.
%% ============================================================================

%% Pick one derivation per supported derived atom. Atoms outside the chosen proof are picked
%% too and simply go unused; constraining the choice to the proof would be circular.
1 { proof_rule(X, R) : head(R, X), triggered_by_in(R) } 1 :- derived_atom(X), supported(X).

%% The chosen tree, walked down from the query.
in_proof(Q) :- query_atom(Q).
in_proof(B) :- in_proof(X), proof_rule(X, R), body(R, B).

%% Its SUPPORT SET: the assumptions it rests on, each once however often it is reached.
support_leaf(L) :- in_proof(L), assumption(L), in(L).

%% Idempotent ⊗: min/max over the set, kept as an atom — grounds linearly, and doubles as the
%% self-check that on these algebras set_weight equals supported_with_weight exactly.
set_weight(W) :- otimes(min), W = #min{ V,L : support_leaf(L), pweight(support, L, V) }.
set_weight(W) :- otimes(max), W = #max{ V,L : support_leaf(L), pweight(support, L, V) }.
#minimize { W@0 : set_weight(W), oplus(min) }.
#maximize { W@0 : set_weight(W), oplus(max) }.

%% Additive ⊗: one objective tuple per distinct leaf — summed natively by the solver, so no
%% subset-sum value is ever grounded. An infinite-weighted leaf contributes no integer tuple
%% and is dropped, matching what the old #sum did with a non-integral tuple.
#minimize { V@0,L : support_leaf(L), pweight(support, L, V),
                    not otimes(min), not otimes(max), oplus(min) }.
#maximize { V@0,L : support_leaf(L), pweight(support, L, V),
                    not otimes(min), not otimes(max), oplus(max) }.

%% Clamped ⊗ is not tuple-separable; refuse rather than silently compute plain Σ. The only
%% shipped algebra this rejects is lukasiewicz (⊗-identity k > 0); the plain-additive algebras
%% have ⊗-identity 0, and the idempotent ones never reach this test.
:- not otimes(min), not otimes(max), otimes_identity(I), I != 0.

#show set_weight/1.
#show support_leaf/1.
