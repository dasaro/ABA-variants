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
%%
%% Dual enforcement approach:
%% 1. Check extension_cost aggregate (for monoids that compute total cost)
%% 2. Check individual discarded attacks (for detecting #sup weights ignored by #sum)
%%
%% Special handling for infinities:
%%   - #sup: Passes when used as "no discards" marker, fails when discarding #sup-weight attacks
%%   - #inf: Always fails (invalid cost)

%% Reject if aggregated extension cost exceeds budget (handles finite costs)
:- extension_cost(C), C > B, budget(B), C != #sup.

%% Reject if extension_cost is #inf (invalid)
:- extension_cost(#inf).

%% Reject if ANY discarded attack has weight #sup with finite budget
%% (infinite cost attack is unaffordable unless budget is also #sup)
%% This catches cases where #sum aggregate ignores #sup values
:- discarded_attack(_,_,#sup), budget(B), B != #sup.
