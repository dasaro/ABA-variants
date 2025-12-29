%% Testing General (δ, β) Pairs for ABA Recovery
%%
%% Goal: Find "general" pairs using only: #inf, #sup, 0, K (for Łukasiewicz)
%%
%% Key constraint behaviors:
%% - constraint/ub.lp line 41: `:- discarded_attack(_,_,#sup), budget(B), B != #sup.`
%% - constraint/lb.lp line 43: `:- discarded_attack(_,_,#sup).`
%%
%% These explicitly reject discarding #sup-weighted attacks!

assumption(a).
assumption(b).
assumption(c).

contrary(b, a).
contrary(c, b).

%% Test 1: Verify δ = #inf works for MIN + LB
%% Give all assumptions weight #inf
weight(a, #inf).
weight(b, #inf).
weight(c, #inf).

%% With MIN + LB and β = 0:
%% - Discard one attack: MIN(#inf) = #inf < 0 ✓ (rejected)
%% - No discards: cost = #sup ≥ 0 ✓ (accepted)
%%
%% Test command:
%%   clingo -n 0 -c beta=0 core/base.lp semiring/godel.lp monoid/baseline/min.lp \
%%          constraint/lb.lp filter/standard.lp semantics/stable.lp \
%%          test/test_aba_recovery_general.lp
