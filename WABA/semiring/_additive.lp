%% ============================================================================
%% _additive.lp — rule-body (⊗ = +) skeleton for the additive family
%% ============================================================================
%% Used by tropical (⊕=min, 0̄=#sup) and arctic (⊕=max, 0̄=#inf). ⊗ is fixed to
%% the integer sum.
%%
%% clingo #sum silently DROPS #sup and #inf, so the two infinities are handled
%% explicitly. For ⊗=+, the additive annihilator is the ⊕-identity 0̄ (x + 0̄ = 0̄):
%%   - any body element = 0̄ (annihilator)            -> result 0̄   (precedence)
%%   - else any body element = the opposite infinity  -> result that infinity
%%   - else                                            -> finite #sum

#include "_phase.lp".

opposite_infinity(#inf) :- oplus_identity(#sup).
opposite_infinity(#sup) :- oplus_identity(#inf).

%% One auxiliary -- "this rule body carries the value V" -- instead of two pre-baked booleans
%% (add_body_has_annih / add_body_has_opp). Each case below now names the algebra constant it
%% tests, so the precedence reads off the rules themselves rather than out of two helper names.
add_body_has(P, R, V) :- body(R, B), pweight(P, B, V).

%% Annihilator wins (a ⊗ 0̄ = 0̄).
rule_deriv(P, R, X, A) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    oplus_identity(A), add_body_has(P, R, A).
%% No annihilator, but the opposite infinity saturates.
rule_deriv(P, R, X, O) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    oplus_identity(A), not add_body_has(P, R, A),
    opposite_infinity(O), add_body_has(P, R, O).
%% Finite case: plain integer sum (no infinities present).
rule_deriv(P, R, X, W) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    oplus_identity(A), not add_body_has(P, R, A),
    opposite_infinity(O), not add_body_has(P, R, O),
    W = #sum{ V,B : body(R,B), pweight(P,B,V) }.
