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
:- extension_cost(C), C < B, budget(B).
