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

otimes_annihilator(A) :- oplus_identity(A).
opposite_infinity(#inf) :- oplus_identity(#sup).
opposite_infinity(#sup) :- oplus_identity(#inf).

add_body_has_annih(P, R) :- body(R, B), pweight(P, B, A), otimes_annihilator(A).
add_body_has_opp(P, R)   :- body(R, B), pweight(P, B, O), opposite_infinity(O).

%% Annihilator wins (a ⊗ 0̄ = 0̄).
rule_deriv(P, R, X, A) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    add_body_has_annih(P, R), otimes_annihilator(A).
%% No annihilator, but the opposite infinity saturates.
rule_deriv(P, R, X, O) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    not add_body_has_annih(P, R), add_body_has_opp(P, R), opposite_infinity(O).
%% Finite case: plain integer sum (no infinities present).
rule_deriv(P, R, X, W) :-
    rule(R), head(R, X), has_body(R), phase_triggered(P, R),
    not add_body_has_annih(P, R), not add_body_has_opp(P, R),
    W = #sum{ V,B : body(R,B), pweight(P,B,V) }.
