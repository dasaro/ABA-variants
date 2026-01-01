%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% FRAMEWORK: Asymmetric Defense Pattern
%%
%% GOAL: Create multiple complete extensions through asymmetric defending
%%
%% STRUCTURE:
%%   - Attacker x attacks both a and b
%%   - Defender d1 defends a (attacks x)
%%   - Defender d2 defends b (attacks x)
%%   - d1 and d2 attack each other
%%
%% ATTACK GRAPH:
%%   x → a
%%   x → b
%%   d1 → x (defends a)
%%   d2 → x (defends b)
%%   d1 → d2
%%   d2 → d1
%%
%% EXPECTED SEMANTICS (β=100, assuming x attacks are cheap to discard):
%%   - Complete: Multiple extensions depending on which defender is accepted
%%     * {d1, a} - d1 defends a, d2 is out
%%     * {d2, b} - d2 defends b, d1 is out
%%     * Possibly ∅ if both defenders defeat each other
%%   - Preferred: Should select maximal among complete
%%   - Grounded: ∅ or minimal defended set
%%
%% KEY DISTINCTION: Preferred ⊂ Complete if preferred selects only maximal
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).

%% Victims
assumption(a).
assumption(b).

%% Attacker (not an assumption - derived)
weight(x, 5).

%% Defenders (assumptions)
assumption(d1).
assumption(d2).

%% Weights
weight(a, 20).
weight(b, 20).
weight(d1, 10).
weight(d2, 10).

%% Contraries for attacks
weight(c_a, 5).
weight(c_b, 5).
weight(c_x, 10).
weight(c_d1, 10).
weight(c_d2, 10).

%% x attacks a and b (derived)
head(r_x_a, c_a).
body(r_x_a, x).

head(r_x_b, c_b).
body(r_x_b, x).

contrary(a, c_a).
contrary(b, c_b).

%% d1 attacks x (defends a)
head(r_d1_x, c_x).
body(r_d1_x, d1).

%% d2 attacks x (defends b)
head(r_d2_x, c_x).
body(r_d2_x, d2).

contrary(x, c_x).

%% d1 and d2 attack each other (mutual exclusion)
head(r_d1_d2, c_d2).
body(r_d1_d2, d1).

head(r_d2_d1, c_d1).
body(r_d2_d1, d2).

contrary(d1, c_d1).
contrary(d2, c_d2).

%% Make x derivable (always present as attacker)
head(r_x, x).
% No body - x is always derivable
