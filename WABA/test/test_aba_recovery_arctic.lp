%% Testing Arctic with δ = 0, β = #inf for UB regime

assumption(a).
assumption(b).
assumption(c).

weight(a, 0).
weight(b, 0).
weight(c, 0).

contrary(b, a).
contrary(c, b).

%% Set budget directly in file
budget(#inf).

%% Arctic + MAX + UB with β = #inf:
%% - Discard: MAX(0) = 0 > #inf ✓ (rejected)
%% - No discard: 0 (accepted)
