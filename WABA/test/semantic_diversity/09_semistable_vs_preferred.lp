%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Force Semi-stable ⊂ Preferred (Strict)
%%
%% GOAL: Two preferred extensions with different ranges, semi-stable picks maximal range
%%
%% STRATEGY:
%%   - Base: unattacked assumption u (always in)
%%   - Branch 1: a, e where a is in, e is attacked by external x1
%%   - Branch 2: b, f, g where b is in, f,g are attacked by external x2
%%   - a and b attack each other (mutually exclusive)
%%
%% ATTACK GRAPH:
%%   u: unattacked (base)
%%   a ⟷ b: mutual (choose one)
%%   x1 → e (e only in if a chosen, extending range)
%%   x2 → f, x2 → g (f,g only in if b chosen, extending range more)
%%
%% EXPECTED:
%%   - Complete: {u,a}, {u,b}
%%   - Preferred: {u,a}, {u,b}
%%   - Semi-stable:
%%     * {u,a}: range = {u,a,b,e} (size 4)
%%     * {u,b}: range = {u,a,b,f,g} (size 5 - LARGER!)
%%     * Semi-stable should prefer {u,b} if range is larger
%%
%% Use zero-weight attacks to avoid discarding complications
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).

assumption(u).
assumption(a).
assumption(b).
assumption(e).
assumption(f).
assumption(g).

weight(u, 10).
weight(a, 10).
weight(b, 10).
weight(e, 10).
weight(f, 10).
weight(g, 10).

%% External attackers (derived, always present)
weight(x1, 0).
weight(x2, 0).

%% Contraries (zero weight)
weight(c_a, 0).
weight(c_b, 0).
weight(c_e, 0).
weight(c_f, 0).
weight(c_g, 0).

%% Make x1 and x2 always derivable
head(r_x1, x1).
head(r_x2, x2).

%% a and b attack each other (mutual exclusion)
head(r_a_b, c_b).
body(r_a_b, a).
contrary(b, c_b).

head(r_b_a, c_a).
body(r_b_a, b).
contrary(a, c_a).

%% x1 attacks e
head(r_x1_e, c_e).
body(r_x1_e, x1).
contrary(e, c_e).

%% x2 attacks f and g
head(r_x2_f, c_f).
body(r_x2_f, x2).
contrary(f, c_f).

head(r_x2_g, c_g).
body(r_x2_g, x2).
contrary(g, c_g).

%% u is unattacked
contrary(u, u).
