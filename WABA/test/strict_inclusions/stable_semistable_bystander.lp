%% Framework demonstrating: stable ⊂ semi-stable (strict)
%%
%% Strategy: Add unattacked "bystander" argument to break symmetry
%%
%% Arguments: a, b, c, d
%% Attacks: a ⟷ b (mutual), d (unattacked bystander)
%% c attacks both a and b
%%
%% Expected:
%% - Stable: {c, d} only (all out arguments defeated)
%% - Semi-stable: {c, d}, {a, d}, {b, d} (all have same maximal range)
%%
%% Reason: {a,d} and {b,d} are admissible with maximal range but not stable
%%         (one of {a,b} is out but not defeated in {a,d} or {b,d})

assumption(a).
assumption(b).
assumption(c).
assumption(d).

%% a ⟷ b (mutual attacks)
contrary(b, a).
contrary(a, b).

%% c attacks a
contrary(a, c).

%% c attacks b
contrary(b, c).

%% d is unattacked (bystander)

weight(a, 100).
weight(b, 100).
weight(c, 100).
weight(d, 100).

#const beta = 0.
budget(beta).
