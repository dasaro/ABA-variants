%% Framework demonstrating: semi-stable ⊂ preferred (strict)
%%
%% AF: 5 arguments with asymmetric ranges
%% att(a,b), att(b,a), att(b,c), att(c,d), att(c,e), att(e,e)
%%
%% Expected:
%% - Preferred: {a,c}, {b,d}
%% - Semi-stable: {a,c} only (maximal range)
%%
%% Ranges:
%% - range({a,c}) = {a,b,c,d,e} (a attacks b, c attacks d,e)
%% - range({b,d}) = {a,b,c,d} (b attacks a,c; d attacks nothing; misses e)
%%
%% Reason: {a,c} has strictly larger range than {b,d}

assumption(a).
assumption(b).
assumption(c).
assumption(d).
assumption(e).

%% att(a,b) → contrary(b,a)
contrary(b, a).

%% att(b,a) → contrary(a,b)
contrary(a, b).

%% att(b,c) → contrary(c,b)
contrary(c, b).

%% att(c,d) → contrary(d,c)
contrary(d, c).

%% att(c,e) → contrary(e,c)
contrary(e, c).

%% att(e,e) → contrary(e,e) (self-attack)
contrary(e, e).

weight(a, 100).
weight(b, 100).
weight(c, 100).
weight(d, 100).
weight(e, 100).

#const beta = 0.
budget(beta).
