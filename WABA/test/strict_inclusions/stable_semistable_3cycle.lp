%% Framework demonstrating: stable ⊂ semi-stable (strict)
%%
%% AF: 3-cycle with att(a,b), att(b,c), att(c,a)
%% WABA: att(X,Y) → contrary(Y,X)
%%
%% Expected:
%% - Stable: ∅ (no stable extensions)
%% - Semi-stable: {a}, {b}, {c} (all preferred with same maximal range)
%%
%% Reason: Triangle has no stable but preferred/semi-stable exist

assumption(a).
assumption(b).
assumption(c).

%% att(a,b) means a attacks b, so contrary(b,a)
contrary(b, a).

%% att(b,c) means b attacks c, so contrary(c,b)
contrary(c, b).

%% att(c,a) means c attacks a, so contrary(a,c)
contrary(a, c).

weight(a, 100).
weight(b, 100).
weight(c, 100).

#const beta = 0.
budget(beta).
