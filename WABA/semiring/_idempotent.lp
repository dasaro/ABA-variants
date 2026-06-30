%% ============================================================================
%% _idempotent.lp — rule-body (⊗) skeleton for the min/max family
%% ============================================================================
%% Used by godel (⊗=min, ⊕=max) and bottleneck_cost (⊗=max, ⊕=min), the two
%% bounded-distributive-lattice algebras. ⊗ is selected by otimes(min|max).
%%
%% No infinity guards are needed: clingo #min/#max drop the off-identity infinity
%% exactly as the lattice requires (#max drops #inf = max-identity; #min drops
%% #sup = min-identity), and keep the annihilating infinity (#max keeps #sup,
%% #min keeps #inf).

#include "_phase.lp".

rule_deriv(P, R, X, W) :-
    otimes(min), rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    W = #min{ V,B : body(R,B), pweight(P,B,V) }.

rule_deriv(P, R, X, W) :-
    otimes(max), rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    W = #max{ V,B : body(R,B), pweight(P,B,V) }.
