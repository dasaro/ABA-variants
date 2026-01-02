%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Framework F28: Explicit Attacks for Semantic Separation
%%
%% GOAL: Use rule-based attacks to create stable < semi-stable < preferred
%%
%% KEY IDEA: Avoid self-attacks entirely. Use conditional attacks via rules.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

budget(100).

%% =============================================================================
%% Assumptions (no self-attacks!)
%% =============================================================================
assumption(a).
assumption(b).
assumption(c).
assumption(d).
assumption(e).
assumption(f).

weight(a, 5).
weight(b, 5).
weight(c, 5).
weight(d, 5).
weight(e, 5).
weight(f, 5).

%% =============================================================================
%% Attack structure using rules
%% =============================================================================

%% a and b mutually attack (weight of attacker applies)
head(r_a_attacks_b, atk_b).
body(r_a_attacks_b, a).
contrary(b, atk_b).  % b is attacked by element atk_b derived from a

head(r_b_attacks_a, atk_a).
body(r_b_attacks_a, b).
contrary(a, atk_a).  % a is attacked by element atk_a derived from b

weight(atk_b, 5).  % Attack from a has weight 5
weight(atk_a, 5).  % Attack from b has weight 5

%% c attacks d (one-way)
head(r_c_attacks_d, atk_d).
body(r_c_attacks_d, c).
contrary(d, atk_d).

weight(atk_d, 5).

%% e and f are unattacked (no contraries defined)
contrary(e, e).  % Placeholder only
contrary(f, f).  % Placeholder only

%% =============================================================================
%% Expected semantics at beta=100:
%% =============================================================================
%%
%% Structure:
%%   - a ↔ b (mutual attack)
%%   - c → d (one-way)
%%   - e, f (unattacked)
%%
%% Grounded: {e, f} (only unattacked assumptions)
%%
%% Complete: {e, f}, {a, e, f}, {b, e, f}, {c, e, f}, {a, c, e, f}, {b, c, e, f}
%%
%% Preferred: Maximal complete
%%   - {a, c, e, f}, {b, c, e, f} (both maximal)
%%
%% Semi-stable: Complete with maximal range
%%   - Range({a, c, e, f}) = {a, b, c, d, e, f} (all atoms)
%%   - Range({b, c, e, f}) = {a, b, c, d, e, f} (all atoms)
%%   - Both have maximal range → both are semi-stable
%%
%% Stable: All out assumptions are attacked
%%   - {a, c, e, f}: out = {b, d, atk_a, atk_b, atk_d}
%%     - Is b attacked? Yes, by atk_b (derived from a) ✓
%%     - Is d attacked? Yes, by atk_d (derived from c) ✓
%%     - Attack elements (atk_*) don't need to be defeated
%%   - So {a, c, e, f} IS stable!
%%   - Similarly {b, c, e, f} IS stable!
%%
%% This STILL gives stable = semi-stable = preferred...
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
