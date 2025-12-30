%% Framework demonstrating: grounded ⊂ ideal (strict)
%%
%% Expected:
%% - Grounded: ∅
%% - Ideal: {a}
%%
%% Reason: In a cycle, grounded is empty but ideal can be non-empty
%%         if there's a universally accepted assumption
%%
%% Modified cycle with one universally defended assumption

assumption(a).
assumption(b).
assumption(c).

%% b and c attack each other (cycle)
contrary(b, c).
contrary(c, b).

%% a attacks nothing and is not attacked
%% Both preferred extensions {a,b} and {a,c} contain a
%% So ideal = {a}, grounded = ∅ (no unattacked assumptions)

weight(a, 100).
weight(b, 100).
weight(c, 100).

#const beta = 0.
budget(beta).
