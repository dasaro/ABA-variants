%% Framework demonstrating: stable ⊂ staged (strict)
%%
%% AF: 3-cycle with att(a,b), att(b,c), att(c,a)
%% WABA: att(X,Y) → contrary(Y,X)
%%
%% Expected:
%% - Stable: ∅ (no stable extensions)
%% - Staged: {a}, {b}, {c} (conflict-free with maximal range)
%%
%% Reason: Staged = range-maximal conflict-free; exists even when stable doesn't

assumption(a).
assumption(b).
assumption(c).

%% att(a,b) → contrary(b,a)
contrary(b, a).

%% att(b,c) → contrary(c,b)
contrary(c, b).

%% att(c,a) → contrary(a,c)
contrary(a, c).

weight(a, 100).
weight(b, 100).
weight(c, 100).

#const beta = 0.
budget(beta).
