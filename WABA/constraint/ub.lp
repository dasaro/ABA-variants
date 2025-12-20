%% WABA Upper Bound (UB) Budget Constraint
%% =========================================
%%
%% Used by: MAX, SUM, COUNT, LEX monoids
%% Semantics: Accept extension iff extension_cost ≤ β
%% Constraint: Reject if extension_cost > β
%%
%% Default: β = #sup (supremum/+∞)
%%   - Permissive: All extensions allowed by default
%%   - Override with -c beta=N to set cost limit
%%
%% Examples:
%%   -c beta=0      # Classical ABA (no discarding allowed)
%%   -c beta=100    # Allow discarding attacks up to total cost 100
%%   -c beta=#sup   # Explicit permissive (same as default)
%%   (no -c beta)   # Uses default #sup (permissive)

#const beta = #sup.
budget(beta).

%% Budget constraint (standard cost limit)
%% Rejects extensions where cost exceeds budget
:- extension_cost(C), C > B, budget(B).
