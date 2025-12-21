%% WABA Lower Bound (LB) Budget Constraint
%% =========================================
%%
%% Used by: MIN monoid
%% Semantics: Accept extension iff extension_cost ≥ β (quality threshold)
%% Constraint: Reject if extension_cost < β
%%
%% Default: β = #inf (infimum/-∞)
%%   - Permissive: All extensions allowed by default
%%   - Override with -c beta=N to set minimum quality threshold
%%
%% Note: Lower values are WORSE quality (cheaper discarded attacks)
%%       Higher values are BETTER quality (only expensive attacks discarded)
%%
%% Examples:
%%   -c beta=#inf   # Explicit permissive (same as default, -∞)
%%   -c beta=0      # Reject if any attack with cost < 0 is discarded
%%   -c beta=10     # Reject if min(discarded attacks) < 10
%%   (no -c beta)   # Uses default #inf (permissive)

#const beta = #inf.
budget(beta).

%% Budget constraint (quality threshold)
%% Rejects extensions where quality (min cost) is too low
%%
%% Dual enforcement approach (same as UB):
%% 1. Check extension_cost aggregate (for quality threshold)
%% 2. Check individual discarded attacks (for detecting #sup weights)
%%
%% Special handling for infinities:
%%   - #sup: Passes when used as "no discards" marker (extension_cost only)
%%           Fails when discarding #sup-weight attacks
%%   - #inf: Worst quality, always fails

%% Standard quality threshold check (handles finite costs)
:- extension_cost(C), C < B, budget(B).

%% Reject if ANY discarded attack has weight #sup
%% For LB (quality threshold), discarding #sup-weight attacks always fails
%% because it's impossible to distinguish from "no discards" (both give cost #sup)
%% This prevents extensions with discards from passing as "best quality"
:- discarded_attack(_,_,#sup).
